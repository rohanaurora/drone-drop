import Cocoa
import CoreLocation

protocol SmartContract {
    func decrypted(delivery: Delivery)
}

class DeliverySmartContract: SmartContract {
    func decrypted(delivery: Delivery) {

    }
}

enum Time: String {
        case extreme = "0000"
        case high = "000"
        case low = "00"
        case fast = "0"
}

class Delivery: Codable {
    
    var sender: String
    var target: String
    var gps: Double
    
    init(sender: String, target: String, gps: Double) {
        self.sender = sender
        self.target = target
        self.gps = gps
    }
}

class Block {
    
    var index: Int = 0
    var previousHash: String = ""
    var hash: String!
    var nonce: Int
    
    private (set) var deliveries: [Delivery] = [Delivery]()
    
    init() {
        self.nonce = 0
    }

    var key: String {
        get {
            let deliveriesData = try! JSONEncoder().encode(self.deliveries)
            let deliveriesJSONString = String(data: deliveriesData, encoding: .utf8)
            return String(self.index) + self.previousHash + String(self.nonce) + deliveriesJSONString!
        }
    }
    
    func addDelivery(delivery: Delivery) {
        self.deliveries.append(delivery)
    }
}

class Blockchain {
    
    private (set) var blocks: [Block] = [Block]()
    private var pWork: String? = Time.low.rawValue
    
    init(genesisBlock: Block, for work: Time? = nil) {
        
        if let time = work { pWork = time.rawValue }
        
        addBlock(genesisBlock)
    }
    
    func addBlock(_ block: Block) {
        
        if self.blocks.isEmpty {
            block.previousHash = "00000000000"
            block.hash = generateHash(for :block)
        }
        
        self.blocks.append(block)
    }
    
    func getNextBlock(deliveries: [Delivery]) -> Block {
        
        let block = Block()
        deliveries.forEach { block.addDelivery(delivery: $0) }
        
        let previousBlock = getPreviousBlock()
        block.index = self.blocks.count
        block.previousHash = previousBlock.hash
        block.hash = generateHash(for: block)
        return block
    }
    
    private func getPreviousBlock() -> Block {
        return self.blocks[self.blocks.count - 1]
    }
    
    func generateHash(for block: Block) -> String {
        var hash = block.key.sha1Hash()
        
        guard let pwork  = pWork else { return "" }
        while (!hash.hasPrefix(pwork)) {
            block.nonce += 1
            hash = block.key.sha1Hash()
            print(hash)
        }
        return hash
    }
}

extension String {
    
    func sha1Hash() -> String {
        
        let task = Process()
        task.launchPath = "/usr/bin/shasum"
        task.arguments = []
        
        let inputPipe = Pipe()
        
        inputPipe.fileHandleForWriting.write(self.data(using: String.Encoding.utf8)!)
        
        inputPipe.fileHandleForWriting.closeFile()
        
        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardInput = inputPipe
        task.launch()
        
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let hash = String(data: data, encoding: String.Encoding.utf8)!
        return hash.replacingOccurrences(of: "  -\n", with: "")
    }
}

let gBlock = Block()
let blockChain = Blockchain(genesisBlock: gBlock, for: .fast)

let delivery = Delivery(sender: "Starlink", target: "Human", gps: 34.052235)
print("\n------------------- Genesis Block found -----------------------------\n")
let testBlock = blockChain.getNextBlock(deliveries: [delivery])
blockChain.addBlock(testBlock)
print("\n ------------------- Hash found -----------------------------\n")
print("Number of blocks in Blockchain: \(blockChain.blocks.count)")

