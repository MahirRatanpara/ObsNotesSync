# Pushing Realtime Updates

## Overview
Pattern for delivering live updates to users as events happen - essential for chat applications, notifications, live dashboards, and any system requiring immediate data synchronization.

## When to Use
- Chat applications
- Notification systems
- Live dashboards
- Collaborative editing tools
- Real-time monitoring systems
- Any scenario where users need immediate updates without manual refresh

## Protocol Choices

### HTTP Polling
**Description**: Client repeatedly requests updates from server at regular intervals

**Pros**:
- Simplest to implement
- Works with standard HTTP infrastructure
- No special server requirements

**Cons**:
- Inefficient - many empty responses
- Higher latency (depends on polling interval)
- Increased server load from constant requests

**When to Use**: Start here until it no longer serves your needs

### Server-Sent Events (SSE)
**Description**: Server pushes updates to client over a single HTTP connection

**Pros**:
- Purpose-built for server-to-client updates
- Automatic reconnection built-in
- Simple protocol over HTTP

**Cons**:
- Unidirectional (server to client only)
- Connection limits in browsers
- Infrastructure complexity increases

**When to Use**: When you need efficient one-way updates from server to client

### WebSockets
**Description**: Full-duplex communication channel over a single TCP connection

**Pros**:
- Bidirectional communication
- Low latency
- Efficient for high-frequency updates

**Cons**:
- More complex infrastructure
- Requires special server support
- Connection state management challenges

**When to Use**: When you need bidirectional, high-frequency communication

## Server-Side Architecture Options

### Pub/Sub Services
**Description**: Decoupled publisher and subscriber model using message brokers

**Components**:
- Message broker (Redis, Kafka, RabbitMQ)
- Publishers (services generating updates)
- Subscribers (connection handlers)

**Pros**:
- Decouples update generation from delivery
- Easy to scale independently
- Multiple subscribers per message

**Cons**:
- Additional infrastructure complexity
- Message ordering challenges
- Potential message loss scenarios

**Use Case**: WhatsApp-style messaging systems

### Stateful Servers with Consistent Hashing
**Description**: Servers maintain long-lived connections, distributed via consistent hashing

**Components**:
- Stateful connection servers
- Consistent hash ring for routing
- Load balancer with sticky sessions

**Pros**:
- Direct connection state management
- Better for heavy processing per connection
- Simpler message routing

**Cons**:
- Server failures impact connected users
- Harder to scale dynamically
- Rebalancing complexity

**Use Case**: Google Docs-style collaborative editing

## Key Design Decisions

### Recommendation
1. **Start Simple**: Begin with HTTP polling
2. **Upgrade When Needed**: Move to SSE/WebSockets when polling becomes inefficient
3. **Choose Server Architecture**: Pub/Sub for simple updates, stateful servers for complex processing

### Trade-offs to Discuss
- **Latency vs Complexity**: Polling is simple