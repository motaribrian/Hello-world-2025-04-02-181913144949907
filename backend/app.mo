import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";

actor SupplyChainVerifier {
  
  // Types
  type ProductId = Text;
  
  type SupplyChainEvent = {
    eventType: Text;
    timestamp: Int;
    location: Text;
    handler: Text;
  };
  
  type VerificationResult = {
    timestamp: Int;
    location: Text;
    isAuthentic: Bool;
    confidenceScore: Float;
    verificationId: Text;
  };
  
  type Product = {
    productId: ProductId;
    productType: Text;
    producer: Text;
    registrationTimestamp: Int;
    registrationLocation: Text;
    supplyChainEvents: [SupplyChainEvent];
    verifications: [VerificationResult];
  };
  
  // State
  private stable var nextVerificationId : Nat = 0;
  private stable var productEntries : [(ProductId, Product)] = [];
  private var productDatabase = HashMap.HashMap<ProductId, Product>(0, Text.equal, Text.hash);
  private var verificationLogs = Buffer.Buffer<(ProductId, VerificationResult)>(0);
  
  // Initialize from stable storage
  system func preupgrade() {
    productEntries := Iter.toArray(productDatabase.entries());
  };
  
  system func postupgrade() {
    productDatabase := HashMap.fromIter<ProductId, Product>(
      productEntries.vals(), 
      productEntries.size(), 
      Text.equal, 
      Text.hash
    );
    productEntries := [];
  };
  
  // Register a new product
  public func registerProduct(
    productId: ProductId, 
    productType: Text, 
    producer: Text, 
    timestamp: Int, 
    location: Text
  ) : async {
    #success: Bool;
    #product: ?Product;
    #error: ?Text;
  } {
    
    switch (productDatabase.get(productId)) {
      case (?_) {
        return {
          #success = false;
          #product = null;
          #error = ?"Product ID already exists";
        };
      };
      case (null) {
        let newProduct : Product = {
          productId = productId;
          productType = productType;
          producer = producer;
          registrationTimestamp = timestamp;
          registrationLocation = location;
          supplyChainEvents = [];
          verifications = [];
        };
        
        productDatabase.put(productId, newProduct);
        
        return {
          #success = true;
          #product = ?newProduct;
          #error = null;
        };
      };
    };
  };
  
  // Add a supply chain event
  public func addSupplyChainEvent(
    productId: ProductId, 
    eventType: Text, 
    timestamp: Int, 
    location: Text, 
    handler: Text
  ) : async {
    #success: Bool;
    #event: ?SupplyChainEvent;
    #error: ?Text;
  } {
    
    switch (productDatabase.get(productId)) {
      case (null) {
        return {
          #success = false;
          #event = null;
          #error = ?"Product not found";
        };
      };
      case (?product) {
        let event : SupplyChainEvent = {
          eventType = eventType;
          timestamp = timestamp;
          location = location;
          handler = handler;
        };
        
        let updatedEvents = Array.append<SupplyChainEvent>(
          product.supplyChainEvents, 
          [event]
        );
        
        let updatedProduct : Product = {
          productId = product.productId;
          productType = product.productType;
          producer = product.producer;
          registrationTimestamp = product.registrationTimestamp;
          registrationLocation = product.registrationLocation;
          supplyChainEvents = updatedEvents;
          verifications = product.verifications;
        };
        
        productDatabase.put(productId, updatedProduct);
        
        return {
          #success = true;
          #event = ?event;
          #error = null;
        };
      };
    };
  };
  
  // AI-based product verification
  // Note: In a real implementation, we would integrate with an AI service
  // Here we're simulating the AI verification with random confidence scores
  public func verifyProduct(
    productId: ProductId, 
    imageHash: Text, // Instead of raw image data, we use a hash
    timestamp: Int, 
    location: Text
  ) : async {
    #success: Bool;
    #isAuthentic: Bool;
    #confidenceScore: Float;
    #verificationId: Text;
    #error: ?Text;
  } {
    
    switch (productDatabase.get(productId)) {
      case (null) {
        return {
          #success = false;
          #isAuthentic = false;
          #confidenceScore = 0;
          #verificationId = "";
          #error = ?"Product not found";
        };
      };
      case (?product) {
        // Simulate AI verification with pseudorandom confidence score
        // In a real implementation, this would call an AI model
        let hash_value = Text.hash(imageHash);
        let modulo = hash_value % 100;
        let confidenceScore = Float.fromInt(70 + modulo % 30) / 100.0;
        let isAuthentic = confidenceScore > 0.7;
        
        nextVerificationId += 1;
        let verificationId = "ver-" # Int.toText(timestamp) # "-" # Nat.toText(nextVerificationId);
        
        let verificationResult : VerificationResult = {
          timestamp = timestamp;
          location = location;
          isAuthentic = isAuthentic;
          confidenceScore = confidenceScore;
          verificationId = verificationId;
        };
        
        let updatedVerifications = Array.append<VerificationResult>(
          product.verifications, 
          [verificationResult]
        );
        
        let updatedProduct : Product = {
          productId = product.productId;
          productType = product.productType;
          producer = product.producer;
          registrationTimestamp = product.registrationTimestamp;
          registrationLocation = product.registrationLocation;
          supplyChainEvents = product.supplyChainEvents;
          verifications = updatedVerifications;
        };
        
        productDatabase.put(productId, updatedProduct);
        verificationLogs.add((productId, verificationResult));
        
        return {
          #success = true;
          #isAuthentic = isAuthentic;
          #confidenceScore = confidenceScore;
          #verificationId = verificationId;
          #error = null;
        };
      };
    };
  };
  
  // Get product information and history
  public query func getProduct(productId: ProductId) : async {
    #success: Bool;
    #product: ?Product;
    #error: ?Text;
  } {
    
    switch (productDatabase.get(productId)) {
      case (null) {
        return {
          #success = false;
          #product = null;
          #error = ?"Product not found";
        };
      };
      case (?product) {
        return {
          #success = true;
          #product = ?product;
          #error = null;
        };
      };
    };
  };
  
  // Get verification logs
  public query func getVerificationLogs(
    startTimestamp: Int, 
    endTimestamp: Int
  ) : async {
    #success: Bool;
    #logs: [(ProductId, VerificationResult)];
  } {
    
    let filteredLogs = Buffer.Buffer<(ProductId, VerificationResult)>(0);
    
    for ((productId, log) in verificationLogs.vals()) {
      if (log.timestamp >= startTimestamp and log.timestamp <= endTimestamp) {
        filteredLogs.add((productId, log));
      };
    };
    
    return {
      #success = true;
      #logs = Buffer.toArray(filteredLogs);
    };
  };
}