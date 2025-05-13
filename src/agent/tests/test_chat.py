import pytest
from app.models.chat import User, Conversation, Message
from app.core.security import get_password_hash

def create_test_user(db):
    """Create a test user in the database"""
    user = User(
        username="testuser",
        email="test@example.com",
        hashed_password=get_password_hash("password123")
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user

def test_health_check(client):
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}

def test_chat_api_new_conversation(client, db):
    """Test chat API with new conversation"""
    # Create test user
    user = create_test_user(db)

    # Test chat endpoint
    response = client.post(
        "/api/v1/chat",
        headers={"Authorization": f"Bearer {user}"},
        json={"message": "Hello, how are you?"}
    )

    assert response.status_code == 200
    data = response.json()

    assert "message" in data
    assert "conversation_id" in data
    assert data["conversation_id"] > 0

    # Verify conversation and messages were created in DB
    conversation = db.query(Conversation).filter(Conversation.id == data["conversation_id"]).first()
    assert conversation is not None

    messages = db.query(Message).filter(Message.conversation_id == data["conversation_id"]).all()
    assert len(messages) == 2  # User message and assistant response
    assert messages[0].role == "user"
    assert messages[0].content == "Hello, how are you?"
    assert messages[1].role == "assistant"

def test_chat_api_existing_conversation(client, db):
    """Test chat API with existing conversation"""
    # Create test user
    user = create_test_user(db)

    # Create a conversation for the user
    conversation = Conversation(title="Test Conversation", user_id=user.id)
    db.add(conversation)
    db.commit()
    db.refresh(conversation)

    # Add a message to the conversation
    message = Message(
        conversation_id=conversation.id,
        role="user",
        content="Previous message"
    )
    db.add(message)
    db.commit()

    # Test chat endpoint with existing conversation_id
    response = client.post(
        "/api/v1/chat",
        headers={"Authorization": f"Bearer {user}"},
        json={
            "message": "Follow-up question",
            "conversation_id": conversation.id
        }
    )

    assert response.status_code == 200
    data = response.json()

    assert "message" in data
    assert "conversation_id" in data
    assert data["conversation_id"] == conversation.id

    # Verify messages were added to existing conversation
    messages = db.query(Message).filter(Message.conversation_id == conversation.id).all()
    assert len(messages) == 3  # Previous + new user message + assistant response