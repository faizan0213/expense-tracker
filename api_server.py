from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import re
import uvicorn
from typing import Optional, Dict, Any
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Smart Expense Tracker API", version="1.0.0")

class ExpenseTextRequest(BaseModel):
    text: str
    language: str = "mixed"

class ExpenseResponse(BaseModel):
    success: bool
    expense: Optional[Dict[str, Any]] = None
    error: Optional[str] = None

# Categories mapping for Hindi/English words
CATEGORY_KEYWORDS = {
    'food': [
        'khana', 'food', 'restaurant', 'meal', 'breakfast', 'lunch', 'dinner',
        'snacks', 'coffee', 'tea', 'chai', 'nashta', 'khane', 'pizza', 'burger',
        'biryani', 'dal', 'rice', 'roti', 'sabzi', 'sweets', 'mithai', 'khaana'
    ],
    'transport': [
        'transport', 'taxi', 'uber', 'ola', 'bus', 'metro', 'train', 'petrol',
        'diesel', 'fuel', 'auto', 'rickshaw', 'bike', 'car', 'travel', 'safar',
        'yatra', 'ticket', 'parking', 'gaadi'
    ],
    'shopping': [
        'shopping', 'clothes', 'kapde', 'shirt', 'pant', 'shoes', 'jute',
        'market', 'mall', 'online', 'amazon', 'flipkart', 'dress', 'saree',
        'kurta', 'accessories', 'bag', 'purse', 'kharidari'
    ],
    'entertainment': [
        'movie', 'cinema', 'film', 'entertainment', 'game', 'party', 'club',
        'concert', 'music', 'book', 'magazine', 'netflix', 'subscription',
        'youtube', 'spotify', 'manoranjan', 'masti'
    ],
    'bills': [
        'bill', 'electricity', 'bijli', 'water', 'pani', 'gas', 'internet',
        'wifi', 'mobile', 'phone', 'recharge', 'rent', 'kiraya', 'maintenance',
        'society', 'utility'
    ],
    'medical': [
        'medical', 'doctor', 'hospital', 'medicine', 'dawa', 'dawai', 'clinic',
        'checkup', 'treatment', 'ilaj', 'pharmacy', 'health', 'sehat', 'dentist',
        'eye', 'test', 'lab', 'x-ray', 'scan'
    ],
    'education': [
        'education', 'school', 'college', 'university', 'course', 'book', 'kitab',
        'fees', 'tuition', 'coaching', 'class', 'study', 'padhai', 'exam',
        'stationery', 'pen', 'pencil', 'notebook'
    ],
}

# Amount extraction patterns
AMOUNT_PATTERNS = [
    r'(\d+(?:\.\d+)?)\s*(?:rupees?|rs\.?|₹)',
    r'₹\s*(\d+(?:\.\d+)?)',
    r'rs\.?\s*(\d+(?:\.\d+)?)',
    r'(\d+(?:\.\d+)?)\s*(?:rupaye|rupaiye)',
    r'(\d+(?:\.\d+)?)',  # fallback for any number
]

# Expense action words
EXPENSE_ACTIONS = [
    'spent', 'spend', 'kharch', 'kharcha', 'kiye', 'kiya', 'gaye', 'gaya',
    'paid', 'pay', 'diye', 'diya', 'bought', 'buy', 'kharida', 'kharide',
    'liya', 'liye', 'cost', 'costed', 'lagaye', 'laga', 'bill', 'expense'
]

def extract_amount(text: str) -> Optional[float]:
    """Extract amount from text using regex patterns"""
    text_lower = text.lower()
    
    for pattern in AMOUNT_PATTERNS:
        matches = re.findall(pattern, text_lower, re.IGNORECASE)
        if matches:
            try:
                amount = float(matches[0])
                if amount > 0:
                    return amount
            except ValueError:
                continue
    return None

def extract_category(text: str) -> str:
    """Extract category from text based on keywords"""
    text_lower = text.lower()
    
    # Check each category's keywords
    for category, keywords in CATEGORY_KEYWORDS.items():
        for keyword in keywords:
            if keyword.lower() in text_lower:
                return category
    
    return 'other'  # default category

def generate_description(original_text: str, category: str, amount: float) -> str:
    """Generate a clean description from the original text"""
    # Clean up the message to create a description
    description = original_text.strip()
    
    # Remove common expense action words for cleaner description
    words_to_remove = [
        'maine', 'main', 'ne', 'mein', 'me', 'i', 'spent', 'spend', 'paid', 'pay',
        'kiye', 'kiya', 'gaye', 'gaya', 'diye', 'diya', 'kharch', 'kharcha',
        'rupees', 'rupaye', 'rupaiye', 'rs', '₹'
    ]
    
    words = description.split(' ')
    words = [word for word in words 
             if word.lower().strip('.,!?') not in words_to_remove 
             and not re.match(r'^\d+(\.\d+)?$', word.strip('.,!?'))]
    
    description = ' '.join(words).strip()
    
    # If description is too short or empty, generate based on category
    if len(description) < 5:
        category_descriptions = {
            'food': 'Food expense',
            'transport': 'Transportation expense',
            'shopping': 'Shopping expense',
            'entertainment': 'Entertainment expense',
            'bills': 'Bill payment',
            'medical': 'Medical expense',
            'education': 'Education expense',
            'other': 'General expense'
        }
        description = category_descriptions.get(category, 'General expense')
    
    return description

def has_expense_action(text: str) -> bool:
    """Check if text contains expense-related action words"""
    text_lower = text.lower()
    return any(action.lower() in text_lower for action in EXPENSE_ACTIONS)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "message": "Smart Expense Tracker API is running"}

@app.post("/process-expense-text", response_model=ExpenseResponse)
async def process_expense_text(request: ExpenseTextRequest):
    """Process natural language text to extract expense information"""
    try:
        text = request.text.strip()
        
        if not text:
            return ExpenseResponse(
                success=False,
                error="Empty text provided"
            )
        
        logger.info(f"Processing text: {text}")
        
        # Check if message contains expense-related words
        if not has_expense_action(text):
            return ExpenseResponse(
                success=False,
                error="No expense-related action found in the text"
            )
        
        # Extract amount
        amount = extract_amount(text)
        if amount is None or amount <= 0:
            return ExpenseResponse(
                success=False,
                error="Could not extract valid amount from the text"
            )
        
        # Extract category
        category = extract_category(text)
        
        # Generate description
        description = generate_description(text, category, amount)
        
        expense_data = {
            'amount': amount,
            'category': category,
            'description': description,
        }
        
        logger.info(f"Extracted expense: {expense_data}")
        
        return ExpenseResponse(
            success=True,
            expense=expense_data
        )
        
    except Exception as e:
        logger.error(f"Error processing expense text: {str(e)}")
        return ExpenseResponse(
            success=False,
            error=f"Internal server error: {str(e)}"
        )

@app.get("/categories")
async def get_categories():
    """Get available expense categories"""
    return {
        "categories": list(CATEGORY_KEYWORDS.keys()),
        "keywords": CATEGORY_KEYWORDS
    }

@app.get("/examples")
async def get_example_messages():
    """Get example expense messages"""
    return {
        "examples": [
            "Maine 500 rupees khana pe kharch kiye",
            "Transport mein 200 rupees gaye",
            "Shopping ke liye 1500 spend kiye",
            "Medical bill 800 rupees ka tha",
            "Petrol mein 2000 rupees bharwaye",
            "Movie ticket ke liye 300 paid kiye",
            "Electricity bill 1200 rupees ka aaya",
            "Books ke liye 800 rupees kharche",
        ]
    }

if __name__ == "__main__":
    uvicorn.run(
        "api_server:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )