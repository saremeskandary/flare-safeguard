class Policy {
  constructor(data) {
    this.id = data.id;
    this.holder = data.holder;
    this.coverageAmount = data.coverageAmount;
    this.premium = data.premium;
    this.startDate = data.startDate;
    this.endDate = data.endDate;
    this.status = data.status;
    this.ipfsHash = data.ipfsHash;
    this.description = data.description;
    this.type = data.type;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }
}

class Claim {
  constructor(data) {
    this.id = data.id;
    this.policyId = data.policyId;
    this.amount = data.amount;
    this.status = data.status;
    this.timestamp = data.timestamp;
    this.description = data.description;
    this.evidence = data.evidence;
    this.processedBy = data.processedBy;
    this.processedAt = data.processedAt;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }
}

class User {
  constructor(data) {
    this.id = data.id;
    this.address = data.address;
    this.policies = data.policies;
    this.claims = data.claims;
    this.createdAt = data.createdAt;
    this.updatedAt = data.updatedAt;
  }
}

module.exports = {
  Policy,
  Claim,
  User
}; 