//
//  PyTestView.swift
//  minip
//
//  Created by ByteDance on 2023/7/12.
//

import SwiftUI
import Foundation
import Python
import PythonKit
import TreeSitterPythonRunestone

var pipe: Pipe? = nil

var PyStdoutPipe: Pipe? = nil
var PyStderrPipe: Pipe? = nil

struct PyTestView: View {
    @State var input = {
        let defaultRes = """
import time

def fib(n:int) -> int:
  if n <= 2:
    return 1
  return fib(n-2) + fib(n-1)

start = time.time()
res = fib(40)
end = time.time()
print("res: %d, cost: %f s"%(res, end - start))
"""
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let playgroundPath = documentsURL.appendingPathComponent("playground")
        
        let fileURL = playgroundPath.appendingPathComponent("test.py")
        
        let (exist, isFolder) = fileOrFolderExists(path: playgroundPath.path())
        if !exist {
            mkdir(path: playgroundPath.path())
            touch(path: fileURL.path(), content: defaultRes.data(using: .utf8))
            return defaultRes
        } else if isFolder {
            let (e, isF) = fileOrFolderExists(path: fileURL.path())
            if !e {
                touch(path: fileURL.path(), content: defaultRes.data(using: .utf8))
                return defaultRes
            } else if !isF {
                return cat(url: fileURL)
            }
        }
        
        return defaultRes
    }()
    @State var outputs = [PyResultInfo]()
    @State var showRes = false
    @State var isRunning = false
    
    @State var isInited = false
    
    struct PyResultInfo: Identifiable {
        var id = UUID()
        var type: ResultType
        var content: String
        enum ResultType {
            case stdout
            case stderr
        }
    }
    
    
    var body: some View {
        VStack{
            CodeEditorV2View(contentString: $input, language: .python)
                .onChange(of: input, perform: { str in
                    DispatchQueue.main.async {
                        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let playgroundPath = documentsURL.appendingPathComponent("playground")
                        
                        let fileURL = playgroundPath.appendingPathComponent("test.py")
                        saveFile(url: fileURL, content: str)
                    }
                    
                })
                .edgesIgnoringSafeArea(.all).toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            showRes = true
                        } label: {
                            Image(systemName: "pc")
                                .foregroundColor(.secondary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            if Py_IsInitialized() == 0 {
                                initPython()
                            } else {
                            }
                            if !isRunning {
                                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                outputs.removeAll()
                                showRes.toggle()
                                isRunning = true
                                runPython()
                            } else {
                                ShowNotImplement()
                            }
                        } label: {
                            Image(systemName: isRunning ? "xmark.square" : "play")
                                .foregroundColor(.green)
                                .frame(width: 25)
                        }
                    }
                }
                .navigationTitle(Text("playground"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showRes) {
                    resultView()
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button {
                                    if Py_IsInitialized() == 0 {
                                        initPython()
                                    } else {
                                    }
                                    if !isRunning {
                                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        outputs.removeAll()
                                        showRes.toggle()
                                        isRunning = true
                                        runPython()
                                        
                                    } else {
                                        ShowNotImplement()
                                    }
                                } label: {
                                    Image(systemName: isRunning ? "xmark.square" : "play")
                                        .foregroundColor(.green)
                                        .frame(width: 25)
                                }
                            }
                        }
                }
        }
    }
    
    func resultView() -> some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(outputs, id: \.id) { ele in
                    HStack {
                        Text(ele.content)
                            .foregroundColor({
                                switch ele.type {
                                case .stderr:
                                    return .red
                                default:
                                    return .primary
                                }
                            }())
                        Spacer()
                    }
                    
                }
            }
        }
    }
    
    func initPython() {
        guard let stdLibPath = Bundle.main.path(forResource: "Python/python-stdlib", ofType: nil) else { return }
        guard let dynlib = Bundle.main.path(forResource: "Python/python-stdlib/lib-dynload", ofType: nil) else { return }
        guard let sitePath = Bundle.main.path(forResource: "Python/platform-site", ofType: nil) else { return }
        //        setenv("PYTHONUNBUFFERED", "1", 1)
        setenv("PYTHONIOENCODING", "utf-8", 1)
        //        setenv("PYTHONOPTIMIZE", "2", 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        setenv("PYTHONHOME", stdLibPath, 1)
        setenv("PYTHONPATH", "\(stdLibPath):\(dynlib):\(sitePath)", 1)
//        setenv("PYTHONPATH", "\(stdLibPath):\(dynlib)", 1)
        Py_InitializeEx(0)
//        PyThread_init_thread()
        pipe = Pipe()
        PyStdoutPipe = Pipe()
        PyStderrPipe = Pipe()
        guard let stdoutPipe = PyStdoutPipe, let stderrPipe = PyStderrPipe else { return }
        stdoutPipe.fileHandleForReading.readabilityHandler = { handler in
            var str = String(data: handler.availableData, encoding: .utf8) ?? ""
            if str.last == "\n" {
                str.removeLast()
            }
            outputs.append(PyResultInfo(type: .stdout, content: str))
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handler in
            var str = String(data: handler.availableData, encoding: .utf8) ?? ""
            if str.last == "\n" {
                str.removeLast()
            }
            outputs.append(PyResultInfo(type: .stderr, content: str))
        }
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global(qos: .userInitiated).async {
            let stdoutFd = stdoutPipe.fileHandleForWriting.fileDescriptor
            let stderrFd = stderrPipe.fileHandleForWriting.fileDescriptor
            
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let playgroundPath = documentsURL.appendingPathComponent("playground")
            PyRun_SimpleString(
"""
def initRuntime():
    class Unbuffered(object):
       def __init__(self, stream):
           self.stream = stream
       def write(self, data):
           self.stream.write(data)
           self.stream.flush()
       def writelines(self, datas):
           self.stream.writelines(datas)
           self.stream.flush()
       def __getattr__(self, attr):
           return getattr(self.stream, attr)
    import sys, os
    sys.stdout = Unbuffered(os.fdopen(\(stdoutFd), 'w', encoding='utf-8'))
    sys.stderr = Unbuffered(os.fdopen(\(stderrFd), 'w', encoding='utf-8'))
    os.chdir("\(playgroundPath.path())")

initRuntime()
import gc
gc.collect()
del gc
del initRuntime
"""
)
            semaphore.signal()
        }
        semaphore.wait()
        isInited = true
    }
    
    func runPython() {
        DispatchQueue.global(qos: .userInteractive).async {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let playgroundPath = documentsURL.appendingPathComponent("playground")

            let fileURL = playgroundPath.appendingPathComponent("test.py")
            print(Date.now.ticks)
            PyRun_SimpleFileExFlags(fopen(fileURL.path(), "r"), fileURL.lastPathComponent, 0, nil)
            print(Date.now.ticks)
            DispatchQueue.main.async {
                PyStdoutPipe = nil
                PyStderrPipe = nil
                Py_FinalizeEx()
                isRunning = false
            }
        }
    }
}





// fd write

public typealias Agraph_t = Int // Dummy value

public struct AGWriteWrongEncoding: Error { }

func agwrite(_: UnsafeMutablePointer<Agraph_t>, _ filePointer: UnsafeMutablePointer<FILE>) {
    let message = "This is a stub."
    
    _ = message.withCString { cString in
        fputs(cString, stderr)
    }
}

@discardableResult
func use<R>(
    fileDescriptor: Int32,
    mode: UnsafePointer<Int8>!,
    closure: (UnsafeMutablePointer<FILE>) throws -> R
) rethrows -> R {
    // Should prob remove this `!`, but IDK what a sensible recovery mechanism would be.
    let filePointer = fdopen(fileDescriptor, mode)!
    defer { fclose(filePointer) }
    return try closure(filePointer)
    
}

public extension UnsafeMutablePointer where Pointee == Agraph_t {
    func asString() throws -> String {
        let pipe = Pipe()
        
        use(fileDescriptor: pipe.fileHandleForWriting.fileDescriptor, mode: "w") { filePointer in
            agwrite(self, filePointer)
        }
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let output = String(data: data, encoding: .utf8) else {
            throw AGWriteWrongEncoding()
        }
        return output
    }
}

extension String {
    /// Returns a C pointer to pass this `String` to C functions.
    var cValue: UnsafeMutablePointer<Int8> {
        guard let cString = cString(using: .utf8) else {
            let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: 1)
            buffer.pointee = 0
            return buffer
        }
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: cString.count)
        memcpy(buffer, cString, cString.count)
        
        return buffer
    }
}


extension Date {
    var ticks: UInt64 {
        return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
    }
}
