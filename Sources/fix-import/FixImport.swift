import ArgumentParser
import Foundation
import PathKit

@main
struct FixImport: ParsableCommand {
    @Option(name: .shortAndLong, help: "源码目录", completion: CompletionKind.directory)
    var src: String

    @Option(name: .shortAndLong, help: "import 文件")
    var `import`: String
    
    @Option(help: "符号正则, 用于匹配 import 文件中的符号")
    var symbolPattern: String
    
    @Flag(help: "是否仅处理头文件")
    var header = false
    
    func run() throws {
        let start = CFAbsoluteTimeGetCurrent()
        
        let queue = OperationQueue()
        queue.name = "FixImport"
        queue.maxConcurrentOperationCount = ProcessInfo.processInfo.processorCount
        
        let path = Path(src)
        
        let srcExtensions = header ? ["h"] : ["m", "mm"]
        let srcFiles = try path.absolute().recursiveChildren()
            .filter {
                guard $0.isFile else {
                    return false
                }
                
                guard let `extension` = $0.extension, srcExtensions.contains(`extension`) else {
                    return false
                }
                
                let components = $0.components
                guard !components.contains("Pods") else {
                    return false
                }
                
                return true
            }
        
        srcFiles.forEach { filePath in
            let op = BlockOperation {
                do {
//                    let pattern = "MBProgressHUD|TDCreateDefaultHUDWithSuperView|TDCreateDefaultHUD|TDToastWithDuration|TDLoadingHud|TDProcessingHud|TDCustomViewHUD|TDToast"
                    let RE = try NSRegularExpression(pattern: symbolPattern, options: [.caseInsensitive, .anchorsMatchLines])
//                    let pattern2 = "^#import\\s\"(.*?)\""
                    let pattern2 = "^#import\\s(\".*?\"|<.*?>)"
                    let RE2 = try NSRegularExpression(pattern: pattern2, options: [.caseInsensitive, .anchorsMatchLines])
                    
                    let contents = try String(contentsOf: filePath.url)
                    let matchs1 = RE.matches(in: contents, options: .reportProgress, range: NSMakeRange(0, contents.count))
                    guard !matchs1.isEmpty else {
                        return
                    }
                    
                    let matchs2 = RE2.matches(in: contents, options: .reportProgress, range: NSMakeRange(0, contents.count))
                    var exist = false
                    if !matchs2.isEmpty {
                        for match in matchs2 {
                            guard match.numberOfRanges == 2 else {
                                continue
                            }
                            let range = match.range(at: 1)
                            let str = (contents as NSString).substring(with: range)
//                            print(str)
                            guard str == `import` else {
                                continue
                            }
                            exist = true
                            break
                        }
                    }
                    
                    guard !exist, let range = matchs2.last?.range, let copyed = (contents as NSString).mutableCopy() as? NSMutableString else {
                        return
                    }
                    
                    let appeded = "\n#import \(`import`)"
                    copyed.insert(appeded, at: range.location + range.length)
                    try copyed.write(to: filePath.url, atomically: true, encoding: String.Encoding.utf8.rawValue)
                    
                } catch let e {
                    print(e)
                    Darwin.exit(EXIT_FAILURE)
                }
            }
            queue.addOperation(op)
        }
        
        queue.waitUntilAllOperationsAreFinished()
        print("count: \(srcFiles.count) elapsed time: \(String(format: "%.02fs", CFAbsoluteTimeGetCurrent() - start))")
    }
}
