"""
日语词汇PPT图片增强工具 - GUI版本
"""

import os
import sys
import tkinter as tk
from tkinter import filedialog, messagebox, scrolledtext
import threading
from pathlib import Path

# 导入主程序
from main import PPTImageEnhancer

try:
    from tkinterdnd2 import DND_FILES, TkinterDnD
    DND_AVAILABLE = True
except ImportError:
    DND_AVAILABLE = False
    print("[WARN] tkinterdnd2未安装，拖拽功能不可用。请运行: pip install tkinterdnd2")


class PPTEnhancerGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("日语词汇PPT图片增强工具")
        self.root.geometry("900x700")
        self.root.minsize(800, 600)  # 设置最小尺寸
        self.root.resizable(True, True)
        
        # 变量
        self.ppt_path = tk.StringVar()
        self.output_dir = tk.StringVar()
        self.processing = False
        
        # 创建界面
        self.create_widgets()
        
        # 绑定关闭事件
        self.root.protocol("WM_DELETE_WINDOW", self.on_closing)
    
    def create_widgets(self):
        """创建GUI组件"""
        # 标题
        title_label = tk.Label(
            self.root, 
            text="日语词汇PPT图片增强工具",
            font=("Microsoft YaHei", 18, "bold"),
            pady=10
        )
        title_label.pack()
        
        # PPT文件选择区域
        ppt_frame = tk.LabelFrame(self.root, text="PPT文件", font=("Microsoft YaHei", 10), padx=10, pady=10)
        ppt_frame.pack(fill=tk.X, padx=20, pady=10)
        
        # 拖拽区域
        if DND_AVAILABLE:
            self.drop_area = tk.Label(
                ppt_frame,
                text="拖拽PPT文件到这里\n或点击下方按钮选择文件",
                font=("Microsoft YaHei", 11),
                bg="#e8f4f8",
                fg="#333",
                relief=tk.SUNKEN,
                borderwidth=2,
                padx=20,
                pady=30,
                cursor="hand2"
            )
            self.drop_area.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
            
            # 绑定拖拽事件
            self.drop_area.drop_target_register(DND_FILES)
            self.drop_area.dnd_bind('<<Drop>>', self.on_file_drop)
        else:
            self.drop_area = tk.Label(
                ppt_frame,
                text="点击下方按钮选择PPT文件\n（拖拽功能需要安装tkinterdnd2）",
                font=("Microsoft YaHei", 11),
                bg="#f0f0f0",
                fg="#666",
                relief=tk.SUNKEN,
                borderwidth=2,
                padx=20,
                pady=30
            )
            self.drop_area.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)
        
        # 文件路径显示
        self.file_label = tk.Label(
            ppt_frame,
            text="未选择文件",
            font=("Microsoft YaHei", 9),
            fg="#666",
            anchor="w"
        )
        self.file_label.pack(fill=tk.X, padx=5, pady=5)
        
        # 选择文件按钮
        select_file_btn = tk.Button(
            ppt_frame,
            text="选择PPT文件",
            command=self.select_ppt_file,
            font=("Microsoft YaHei", 10),
            bg="#4CAF50",
            fg="white",
            padx=20,
            pady=5,
            cursor="hand2"
        )
        select_file_btn.pack(pady=5)
        
        # 导出文件夹选择区域
        output_frame = tk.LabelFrame(self.root, text="导出设置", font=("Microsoft YaHei", 10), padx=10, pady=10)
        output_frame.pack(fill=tk.X, padx=20, pady=10)
        
        output_dir_label = tk.Label(
            output_frame,
            text="导出文件夹:",
            font=("Microsoft YaHei", 9),
            anchor="w"
        )
        output_dir_label.pack(fill=tk.X, padx=5)
        
        output_path_frame = tk.Frame(output_frame)
        output_path_frame.pack(fill=tk.X, padx=5, pady=5)
        
        self.output_entry = tk.Entry(
            output_path_frame,
            textvariable=self.output_dir,
            font=("Microsoft YaHei", 9),
            state="readonly"
        )
        self.output_entry.pack(side=tk.LEFT, fill=tk.X, expand=True)
        
        select_output_btn = tk.Button(
            output_path_frame,
            text="选择文件夹",
            command=self.select_output_dir,
            font=("Microsoft YaHei", 9),
            bg="#2196F3",
            fg="white",
            padx=15,
            pady=3,
            cursor="hand2"
        )
        select_output_btn.pack(side=tk.LEFT, padx=(5, 0))
        
        # 控制按钮区域 - 先创建并固定在底部
        control_frame = tk.Frame(self.root, bg="#f0f0f0")
        control_frame.pack(fill=tk.X, padx=20, pady=15, side=tk.BOTTOM)
        
        # 按钮容器，使用grid布局确保按钮居中
        btn_container = tk.Frame(control_frame, bg="#f0f0f0")
        btn_container.pack(expand=True)
        
        # 日志区域 - 在按钮区域上方
        log_frame = tk.LabelFrame(self.root, text="处理日志", font=("Microsoft YaHei", 10), padx=10, pady=10)
        log_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)
        
        self.log_text = scrolledtext.ScrolledText(
            log_frame,
            font=("Consolas", 9),
            bg="#1e1e1e",
            fg="#d4d4d4",
            wrap=tk.WORD,
            state=tk.DISABLED
        )
        self.log_text.pack(fill=tk.BOTH, expand=True)
        
        # 配置日志文本颜色标签
        self.log_text.tag_config("info", foreground="#4EC9B0")
        self.log_text.tag_config("success", foreground="#4EC9B0")
        self.log_text.tag_config("error", foreground="#F48771")
        self.log_text.tag_config("warning", foreground="#DCDCAA")
        self.log_text.tag_config("debug", foreground="#9CDCFE")
        
        self.start_btn = tk.Button(
            btn_container,
            text="▶ 开始处理",
            command=self.start_processing,
            font=("Microsoft YaHei", 12, "bold"),
            bg="#4CAF50",
            fg="white",
            padx=30,
            pady=12,
            cursor="hand2",
            state=tk.NORMAL,
            relief=tk.RAISED,
            bd=2
        )
        self.start_btn.grid(row=0, column=0, padx=10, pady=5)
        
        self.stop_btn = tk.Button(
            btn_container,
            text="⏹ 停止",
            command=self.stop_processing,
            font=("Microsoft YaHei", 12),
            bg="#f44336",
            fg="white",
            padx=30,
            pady=12,
            cursor="hand2",
            state=tk.DISABLED,
            relief=tk.RAISED,
            bd=2
        )
        self.stop_btn.grid(row=0, column=1, padx=10, pady=5)
        
        self.clear_log_btn = tk.Button(
            btn_container,
            text="🗑 清空日志",
            command=self.clear_log,
            font=("Microsoft YaHei", 10),
            bg="#757575",
            fg="white",
            padx=20,
            pady=12,
            cursor="hand2",
            relief=tk.RAISED,
            bd=2
        )
        self.clear_log_btn.grid(row=0, column=2, padx=10, pady=5)
        
        # 初始日志
        self.log("欢迎使用日语词汇PPT图片增强工具！", "info")
        self.log("请选择PPT文件并设置导出文件夹", "info")
        if not DND_AVAILABLE:
            self.log("提示: 安装 tkinterdnd2 可使用拖拽功能 (pip install tkinterdnd2)", "warning")
    
    def on_file_drop(self, event):
        """处理文件拖拽事件"""
        files = self.root.tk.splitlist(event.data)
        if files:
            file_path = files[0]
            if file_path.lower().endswith(('.pptx', '.ppt')):
                self.ppt_path.set(file_path)
                self.file_label.config(text=f"已选择: {os.path.basename(file_path)}", fg="#4CAF50")
                self.log(f"已选择文件: {file_path}", "success")
                # 如果尚未选择导出文件夹，默认使用PPT所在文件夹
                if not self.output_dir.get():
                    ppt_dir = os.path.dirname(file_path)
                    self.output_dir.set(ppt_dir)
                    self.log(f"未选择导出文件夹，已自动使用PPT所在文件夹: {ppt_dir}", "info")
            else:
                messagebox.showerror("错误", "请选择PPT文件 (.pptx 或 .ppt)")
                self.log(f"错误: 不支持的文件格式 - {file_path}", "error")
    
    def select_ppt_file(self):
        """选择PPT文件"""
        file_path = filedialog.askopenfilename(
            title="选择PPT文件",
            filetypes=[
                ("PowerPoint文件", "*.pptx *.ppt"),
                ("PowerPoint 2007+", "*.pptx"),
                ("PowerPoint 97-2003", "*.ppt"),
                ("所有文件", "*.*")
            ]
        )
        
        if file_path:
            self.ppt_path.set(file_path)
            self.file_label.config(text=f"已选择: {os.path.basename(file_path)}", fg="#4CAF50")
            self.log(f"已选择文件: {file_path}", "success")
            # 如果尚未选择导出文件夹，默认使用PPT所在文件夹
            if not self.output_dir.get():
                ppt_dir = os.path.dirname(file_path)
                self.output_dir.set(ppt_dir)
                self.log(f"未选择导出文件夹，已自动使用PPT所在文件夹: {ppt_dir}", "info")
    
    def select_output_dir(self):
        """选择导出文件夹"""
        dir_path = filedialog.askdirectory(title="选择导出文件夹")
        
        if dir_path:
            self.output_dir.set(dir_path)
            self.log(f"导出文件夹: {dir_path}", "info")
    
    def log(self, message, tag="info"):
        """添加日志"""
        self.log_text.config(state=tk.NORMAL)
        self.log_text.insert(tk.END, f"{message}\n", tag)
        self.log_text.see(tk.END)
        self.log_text.config(state=tk.DISABLED)
        self.root.update_idletasks()
    
    def clear_log(self):
        """清空日志"""
        self.log_text.config(state=tk.NORMAL)
        self.log_text.delete(1.0, tk.END)
        self.log_text.config(state=tk.DISABLED)
    
    def start_processing(self):
        """开始处理"""
        if not self.ppt_path.get():
            messagebox.showerror("错误", "请先选择PPT文件！")
            return
        
        if not os.path.exists(self.ppt_path.get()):
            messagebox.showerror("错误", "PPT文件不存在！")
            return
        
        # 设置输出路径
        output_path = None
        if self.output_dir.get():
            base_name = os.path.splitext(os.path.basename(self.ppt_path.get()))[0]
            output_path = os.path.join(self.output_dir.get(), f"{base_name}_enhanced.pptx")
        else:
            # 如果没有选择导出文件夹，使用原文件所在目录
            base_name = os.path.splitext(self.ppt_path.get())[0]
            output_path = f"{base_name}_enhanced.pptx"
        
        # 禁用开始按钮，启用停止按钮
        self.start_btn.config(state=tk.DISABLED)
        self.stop_btn.config(state=tk.NORMAL)
        self.processing = True
        
        # 在新线程中处理
        thread = threading.Thread(target=self.process_ppt, args=(self.ppt_path.get(), output_path))
        thread.daemon = True
        thread.start()
    
    def process_ppt(self, ppt_path, output_path):
        """处理PPT（在后台线程中运行）"""
        try:
            self.log("=" * 60, "info")
            self.log(f"开始处理PPT: {ppt_path}", "info")
            self.log(f"输出路径: {output_path}", "info")
            self.log("=" * 60, "info")
            
            # 加载配置
            from main import load_config
            google_api_key, google_cse_id, spark_api_key, spark_base_url, spark_model = load_config()
            
            # 创建增强器
            enhancer = PPTImageEnhancer(
                ppt_path,
                output_path=output_path,
                google_api_key=google_api_key,
                google_cse_id=google_cse_id,
                spark_api_key=spark_api_key,
                spark_base_url=spark_base_url,
                spark_model=spark_model,
                verbose=True
            )
            
            # 创建一个自定义的输出类来捕获print输出
            class GUILogger:
                def __init__(self, gui_app):
                    self.gui_app = gui_app
                
                def write(self, message):
                    if message.strip():
                        tag = "info"
                        if "[DEBUG]" in message:
                            tag = "debug"
                        elif "✓" in message or "成功" in message or "完成" in message:
                            tag = "success"
                        elif "✗" in message or "失败" in message or "错误" in message or "ERROR" in message:
                            tag = "error"
                        elif "警告" in message or "WARN" in message:
                            tag = "warning"
                        self.gui_app.log(message.strip(), tag)
                
                def flush(self):
                    pass
            
            # 重定向stdout
            import sys
            original_stdout = sys.stdout
            sys.stdout = GUILogger(self)
            
            try:
                # 处理幻灯片
                enhancer.process_slides()
                
                self.log("=" * 60, "success")
                self.log("处理完成！", "success")
                self.log(f"输出文件: {output_path}", "success")
                self.log("=" * 60, "success")
                
                # 使用after确保在主线程中显示消息框
                self.root.after(0, lambda: messagebox.showinfo("完成", f"处理完成！\n\n输出文件:\n{output_path}"))
                
            finally:
                # 恢复stdout
                sys.stdout = original_stdout
            
        except Exception as e:
            self.log(f"处理出错: {str(e)}", "error")
            import traceback
            self.log(traceback.format_exc(), "error")
            messagebox.showerror("错误", f"处理失败:\n{str(e)}")
        
        finally:
            # 恢复按钮状态
            self.root.after(0, self.reset_buttons)
    
    def reset_buttons(self):
        """重置按钮状态"""
        self.start_btn.config(state=tk.NORMAL)
        self.stop_btn.config(state=tk.DISABLED)
        self.processing = False
    
    def stop_processing(self):
        """停止处理"""
        if messagebox.askyesno("确认", "确定要停止处理吗？"):
            self.processing = False
            self.log("用户请求停止处理", "warning")
            self.reset_buttons()
    
    def on_closing(self):
        """关闭窗口时的处理"""
        if self.processing:
            if messagebox.askyesno("确认", "正在处理中，确定要退出吗？"):
                self.processing = False
                self.root.destroy()
        else:
            self.root.destroy()


def main():
    """主函数"""
    if DND_AVAILABLE:
        root = TkinterDnD.Tk()
    else:
        root = tk.Tk()
    
    app = PPTEnhancerGUI(root)
    root.mainloop()


if __name__ == "__main__":
    main()

