"""
日语词汇PPT图片增强工具 - Web API版本
部署在服务器上，提供RESTful API接口
"""

import os
import uuid
import shutil
from flask import Flask, request, jsonify, send_file, after_this_request
from flask_cors import CORS
from werkzeug.utils import secure_filename
import tempfile
import traceback

from main import PPTImageEnhancer, load_config

app = Flask(__name__)
CORS(app)  # 允许跨域请求

# 配置
UPLOAD_FOLDER = 'uploads'
OUTPUT_FOLDER = 'outputs'
ALLOWED_EXTENSIONS = {'pptx', 'ppt'}
MAX_FILE_SIZE = 100 * 1024 * 1024  # 100MB

# 确保文件夹存在
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(OUTPUT_FOLDER, exist_ok=True)

# 加载配置（从环境变量或config.json）
google_api_key, google_cse_id, google_ai_api_key, spark_api_key, spark_base_url, spark_model = load_config()

# 如果环境变量中有配置，优先使用环境变量
google_api_key = os.getenv('GOOGLE_API_KEY', google_api_key)
google_cse_id = os.getenv('GOOGLE_CSE_ID', google_cse_id)
google_ai_api_key = os.getenv('GOOGLE_AI_API_KEY', google_ai_api_key)
spark_api_key = os.getenv('SPARK_API_KEY', spark_api_key)
spark_base_url = os.getenv('SPARK_BASE_URL', spark_base_url)
spark_model = os.getenv('SPARK_MODEL', spark_model)


def allowed_file(filename):
    """检查文件扩展名是否允许"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# 全局任务状态存储（用于进度查询）
task_status = {}


class ProgressLogger:
    """用于捕获处理进度的日志类，同时转发到原始stdout，方便在服务器日志中查看完整输出"""
    def __init__(self, original_stdout=None, task_id=None):
        self.logs = []
        self.original_stdout = original_stdout
        self.task_id = task_id
        self.current_page = 0
        self.total_pages = 0
        self.progress_percent = 0
    
    def write(self, message):
        # 记录到内存日志
        if message.strip():
            self.logs.append(message.strip())
            
            # 解析进度信息（例如："[####################] 100% (37/37 pages)"）
            import re
            progress_match = re.search(r'(\d+)% \((\d+)/(\d+) pages\)', message)
            if progress_match:
                self.progress_percent = int(progress_match.group(1))
                self.current_page = int(progress_match.group(2))
                self.total_pages = int(progress_match.group(3))
                
                # 更新全局任务状态
                if self.task_id:
                    task_status[self.task_id] = {
                        'status': 'processing',
                        'progress': self.progress_percent,
                        'current_page': self.current_page,
                        'total_pages': self.total_pages,
                        'logs': self.logs[-50:]  # 只保留最后50条日志
                    }
        
        # 同时转发到原stdout，这样 journalctl 里也能看到完整日志
        if self.original_stdout is not None:
            try:
                self.original_stdout.write(message)
            except Exception:
                # 避免因为日志转发失败影响主流程
                pass
    
    def flush(self):
        if self.original_stdout is not None:
            try:
                self.original_stdout.flush()
            except Exception:
                pass
    
    def get_logs(self):
        return self.logs


@app.route('/api/progress/<task_id>', methods=['GET'])
def get_progress(task_id):
    """获取任务处理进度"""
    if task_id not in task_status:
        return jsonify({'error': '任务不存在'}), 404
    
    status = task_status[task_id]
    return jsonify(status)


@app.route('/api/health', methods=['GET'])
def health_check():
    """健康检查接口
    
    注意：这里只报告后端是否支持这些提供商，不会返回任何API密钥。
    用户可以在前端单独配置自己的API Key，这些Key只在当前请求中使用，不会保存到服务器。
    """
    return jsonify({
        'status': 'ok',
        'message': 'PPT图片增强服务运行正常',
        'supports_google_custom_search': True,
        'supports_google_ai': True,
        'supports_spark_ai': True,
        # 仅表示后端代码支持这些类型，不代表已经配置好密钥
        'server_google_api_configured': bool(google_api_key and google_cse_id),
        'server_google_ai_configured': bool(google_ai_api_key),
        'server_spark_api_configured': bool(spark_api_key)
    })


@app.route('/api/process', methods=['POST'])
def process_ppt():
    """处理PPT文件的主接口"""
    if 'file' not in request.files:
        return jsonify({'error': '没有上传文件'}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': '文件名为空'}), 400
    
    if not allowed_file(file.filename):
        return jsonify({'error': '不支持的文件格式，请上传.pptx或.ppt文件'}), 400
    
    # 检查文件大小
    file.seek(0, os.SEEK_END)
    file_size = file.tell()
    file.seek(0)
    
    if file_size > MAX_FILE_SIZE:
        return jsonify({'error': f'文件太大，最大支持{MAX_FILE_SIZE // 1024 // 1024}MB'}), 400
    
    # 读取用户在前端配置的API Key（可选，优先级高于服务器配置）
    # 这些Key只在本次请求中使用，不会保存到任何地方
    req_google_api_key = request.form.get('google_api_key') or google_api_key
    req_google_cse_id = request.form.get('google_cse_id') or google_cse_id
    req_google_ai_api_key = request.form.get('google_ai_api_key') or google_ai_api_key
    req_spark_api_key = request.form.get('spark_api_key') or spark_api_key
    req_spark_base_url = request.form.get('spark_base_url') or spark_base_url
    req_spark_model = request.form.get('spark_model') or spark_model
    
    # 生成唯一ID
    task_id = str(uuid.uuid4())
    upload_path = None
    output_path = None
    
    try:
        # 保存上传的文件
        filename = secure_filename(file.filename)
        upload_path = os.path.join(UPLOAD_FOLDER, f"{task_id}_{filename}")
        file.save(upload_path)
        
        # 生成输出文件路径
        base_name = os.path.splitext(filename)[0]
        output_filename = f"{base_name}_enhanced.pptx"
        output_path = os.path.join(OUTPUT_FOLDER, f"{task_id}_{output_filename}")
        
        # 创建进度日志捕获器
        import sys
        original_stdout = sys.stdout
        progress_logger = ProgressLogger(original_stdout=original_stdout, task_id=task_id)
        
        # 初始化任务状态
        task_status[task_id] = {
            'status': 'processing',
            'progress': 0,
            'current_page': 0,
            'total_pages': 0,
            'logs': []
        }
        
        # 重定向stdout到进度捕获器
        sys.stdout = progress_logger
        
        try:
            # 创建增强器并处理（优先使用用户在前端传入的API Key）
            enhancer = PPTImageEnhancer(
                upload_path,
                output_path=output_path,
                google_api_key=req_google_api_key,
                google_cse_id=req_google_cse_id,
                google_ai_api_key=req_google_ai_api_key,
                spark_api_key=req_spark_api_key,
                spark_base_url=req_spark_base_url,
                spark_model=req_spark_model,
                verbose=True
            )
            
            enhancer.process_slides()
            
            # 检查输出文件是否存在
            if not os.path.exists(output_path):
                raise Exception("处理完成但输出文件不存在")
            
            # 更新任务状态为完成
            task_status[task_id] = {
                'status': 'success',
                'progress': 100,
                'current_page': progress_logger.total_pages,
                'total_pages': progress_logger.total_pages,
                'logs': progress_logger.get_logs(),
                'output_filename': output_filename
            }
            
            # 返回成功响应（返回全部日志，不再截断）
            return jsonify({
                'status': 'success',
                'task_id': task_id,
                'message': '处理完成',
                'output_filename': output_filename,
                'logs': progress_logger.get_logs()  # 返回全部日志
            })
            
        finally:
            # 恢复stdout
            sys.stdout = original_stdout
            
            # 清理上传的文件
            if upload_path and os.path.exists(upload_path):
                try:
                    os.remove(upload_path)
                except:
                    pass
    
    except Exception as e:
        error_msg = str(e)
        error_trace = traceback.format_exc()
        
        # 更新任务状态为失败
        if 'task_id' in locals():
            task_status[task_id] = {
                'status': 'error',
                'error': error_msg,
                'logs': progress_logger.get_logs() if 'progress_logger' in locals() else []
            }
        
        # 清理文件
        if upload_path and os.path.exists(upload_path):
            try:
                os.remove(upload_path)
            except:
                pass
        if output_path and os.path.exists(output_path):
            try:
                os.remove(output_path)
            except:
                pass
        
        return jsonify({
            'status': 'error',
            'error': error_msg,
            'trace': error_trace if app.debug else None
        }), 500


@app.route('/api/download/<task_id>', methods=['GET'])
def download_ppt(task_id):
    """下载处理后的PPT文件"""
    # 查找对应的输出文件
    output_files = [f for f in os.listdir(OUTPUT_FOLDER) if f.startswith(task_id + '_')]
    
    if not output_files:
        return jsonify({'error': '文件不存在或已过期'}), 404
    
    output_filename = output_files[0]
    output_path = os.path.join(OUTPUT_FOLDER, output_filename)
    
    # 提取原始文件名（去掉task_id前缀）
    original_filename = output_filename[len(task_id) + 1:]
    
    @after_this_request
    def remove_file(response):
        """在响应发送完成后立刻删除输出文件，避免占用磁盘"""
        try:
            if os.path.exists(output_path):
                os.remove(output_path)
        except Exception:
            # 删除失败不影响用户下载
            pass
        return response
    
    return send_file(
        output_path,
        as_attachment=True,
        download_name=original_filename,
        mimetype='application/vnd.openxmlformats-officedocument.presentationml.presentation'
    )


@app.route('/api/cleanup', methods=['POST'])
def cleanup():
    """清理旧文件（可选的管理接口）"""
    try:
        # 清理uploads文件夹中超过1小时的文件
        import time
        current_time = time.time()
        cleaned_count = 0
        
        for filename in os.listdir(UPLOAD_FOLDER):
            file_path = os.path.join(UPLOAD_FOLDER, filename)
            if os.path.isfile(file_path):
                if current_time - os.path.getmtime(file_path) > 3600:  # 1小时
                    os.remove(file_path)
                    cleaned_count += 1
        
        # 清理outputs文件夹中超过24小时的文件
        for filename in os.listdir(OUTPUT_FOLDER):
            file_path = os.path.join(OUTPUT_FOLDER, filename)
            if os.path.isfile(file_path):
                if current_time - os.path.getmtime(file_path) > 86400:  # 24小时
                    os.remove(file_path)
                    cleaned_count += 1
        
        return jsonify({
            'status': 'success',
            'cleaned_files': cleaned_count
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    # 开发环境配置
    app.run(host='0.0.0.0', port=5000, debug=False)
    
    # 生产环境建议使用gunicorn:
    # gunicorn -w 4 -b 0.0.0.0:5000 web_app:app

