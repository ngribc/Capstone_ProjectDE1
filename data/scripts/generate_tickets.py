"""
generate_tickets.py
===================
Genera customer_support_tickets.csv sintético a partir de FakeStore API.
Los tickets son realistas: usan los productos reales (id, title, category, price)
y simulan el comportamiento de soporte de un e-commerce.

USO:
    python3 generate_tickets.py                     # 500 tickets, seeds fijos
    python3 generate_tickets.py --rows 2000         # 2000 tickets
    python3 generate_tickets.py --rows 1000 --seed 99

SALIDA:
    ./data/customer_support_tickets.csv
"""

import argparse
import random
import csv
import os
import json
import urllib.request
from datetime import datetime, timedelta, timezone

# ── Config ────────────────────────────────────────────────────────────────────
API_URL    = "https://fakestoreapi.com/products"
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "customer_support_tickets.csv")

# ── Datos sintéticos por categoría ───────────────────────────────────────────
# Cada categoría tiene su propio mix de problemas típicos de e-commerce

ISSUE_TYPES_BY_CATEGORY = {
    "electronics": [
        "Device not turning on",
        "Battery drains too fast",
        "Screen flickering",
        "Overheating issue",
        "Connectivity problem",
        "Missing accessories",
        "Dead on arrival",
    ],
    "jewelery": [
        "Item arrived damaged",
        "Wrong size delivered",
        "Color different from photo",
        "Clasp broken on arrival",
        "Missing certificate of authenticity",
        "Tarnished finish",
    ],
    "men's clothing": [
        "Wrong size delivered",
        "Fabric quality issue",
        "Color fading after wash",
        "Stitching coming apart",
        "Item not as described",
        "Missing item in order",
    ],
    "women's clothing": [
        "Wrong size delivered",
        "Fabric quality issue",
        "Color different from photo",
        "Zipper broken",
        "Item not as described",
        "Return request",
    ],
}

# Fallback para categorías desconocidas
DEFAULT_ISSUES = [
    "Item not as described",
    "Delivery delay",
    "Wrong item received",
    "Damaged packaging",
    "Missing item",
    "Refund request",
]

TICKET_SUBJECTS_TEMPLATES = [
    "Need help with my order #{order_id}",
    "Problem with {product_name}",
    "Issue: {issue_type}",
    "Urgent: {issue_type} - Order #{order_id}",
    "Follow up on {product_name}",
]

RESOLUTIONS = [
    "Replacement sent",
    "Full refund issued",
    "Partial refund applied",
    "Exchange processed",
    "Technical support provided",
    "Escalated to warehouse team",
    "Issue resolved via phone",
    "Customer declined resolution",
    "Awaiting customer response",
    "Closed - no response",
]

STATUSES = ["Open", "Pending", "Closed", "Resolved", "Escalated"]

# Pesos de satisfacción por tipo de resolución (más realista que random puro)
SATISFACTION_BY_RESOLUTION = {
    "Full refund issued":          [4, 5, 5, 5],
    "Replacement sent":            [3, 4, 5, 5],
    "Partial refund applied":      [2, 3, 4, 4],
    "Exchange processed":          [3, 4, 4, 5],
    "Technical support provided":  [3, 3, 4, 5],
    "Escalated to warehouse team": [2, 2, 3, 4],
    "Issue resolved via phone":    [4, 4, 5, 5],
    "Customer declined resolution":[1, 2, 3, 3],
    "Awaiting customer response":  [2, 3, 3, 4],
    "Closed - no response":        [1, 1, 2, 3],
}

FIRST_NAMES = [
    "James", "Mary", "John", "Patricia", "Robert", "Jennifer", "Michael",
    "Linda", "William", "Barbara", "David", "Susan", "Richard", "Jessica",
    "Lucas", "Sofia", "Mateo", "Valentina", "Diego", "Camila", "Andres",
    "Ana", "Carlos", "Maria", "Luis", "Laura", "Jorge", "Elena",
]
LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
    "Davis", "Wilson", "Moore", "Taylor", "Anderson", "Thomas", "Jackson",
    "Lopez", "Martinez", "Gonzalez", "Hernandez", "Rodriguez", "Sanchez",
    "Perez", "Torres", "Ramirez", "Flores", "Rivera", "Morales",
]

CHANNELS = ["Email", "Chat", "Phone", "Social Media", "Self-Service Portal"]

# ── Helpers ───────────────────────────────────────────────────────────────────

def fetch_products() -> list[dict]:
    print(f"[INFO] Fetching products from {API_URL} ...")
    # Agregamos el encabezado para simular una petición de navegador
    req = urllib.request.Request(API_URL, headers={'User-Agent': 'Mozilla/5.0'})
    with urllib.request.urlopen(req, timeout=15) as r:
        products = json.loads(r.read().decode())
    print(f"[INFO] {len(products)} products fetched")
    return products

def random_date(start_days_ago: int = 365, end_days_ago: int = 0) -> str:
    """Returns a random date string between start_days_ago and end_days_ago."""
    now   = datetime.now(timezone.utc)
    start = now - timedelta(days=start_days_ago)
    end   = now - timedelta(days=end_days_ago)
    delta = end - start
    rand  = start + timedelta(seconds=random.randint(0, int(delta.total_seconds())))
    return rand.strftime("%Y-%m-%d")


def resolution_time(status: str) -> float:
    """Simulates resolution time in hours based on status."""
    if status in ("Closed", "Resolved"):
        return round(random.uniform(1, 72), 1)
    elif status == "Escalated":
        return round(random.uniform(24, 168), 1)
    else:
        return round(random.uniform(0, 24), 1)


def generate_ticket(ticket_num: int, product: dict) -> dict:
    category = product.get("category", "unknown")
    issues   = ISSUE_TYPES_BY_CATEGORY.get(category, DEFAULT_ISSUES)
    issue    = random.choice(issues)
    order_id = random.randint(10000, 99999)

    subject_tpl = random.choice(TICKET_SUBJECTS_TEMPLATES)
    subject = subject_tpl.format(
        order_id=order_id,
        product_name=product["title"][:30],
        issue_type=issue,
    )

    resolution = random.choice(RESOLUTIONS)
    status     = random.choice(STATUSES)

    # Closed/Resolved tickets siempre tienen resolución real
    if status in ("Closed", "Resolved") and "Waiting" in resolution:
        resolution = random.choice(["Full refund issued", "Replacement sent", "Exchange processed"])

    sat_pool = SATISFACTION_BY_RESOLUTION.get(resolution, [1, 2, 3, 4, 5])
    satisfaction = random.choice(sat_pool)

    purchase_date = random_date(start_days_ago=365)
    first = random.choice(FIRST_NAMES)
    last  = random.choice(LAST_NAMES)

    return {
        "Ticket ID":                    f"TKT-{ticket_num:06d}",
        "Customer Name":                f"{first} {last}",
        "Customer Email":               f"{first.lower()}.{last.lower()}@example.com",
        "Customer Age":                 random.randint(18, 72),
        "Customer Gender":              random.choice(["Male", "Female", "Non-binary", "Prefer not to say"]),
        "Product Purchased":            product["title"],
        "Product ID":                   product["id"],         # ← FK real hacia FakeStore
        "Category":                     category,
        "Price USD":                    product["price"],
        "Date of Purchase":             purchase_date,
        "Ticket Type":                  issue,
        "Ticket Subject":               subject,
        "Ticket Description":           f"Customer reported: {issue} for order #{order_id}. "
                                        f"Product: {product['title'][:50]}.",
        "Ticket Status":                status,
        "Resolution":                   resolution,
        "Resolution Time (hrs)":        resolution_time(status),
        "Customer Satisfaction Rating": satisfaction,
        "Channel":                      random.choice(CHANNELS),
        "Order ID":                     order_id,
        "snapshot_month":               datetime.now(timezone.utc).strftime("%Y-%m"),
    }


def generate_tickets(products: list[dict], n_rows: int) -> list[dict]:
    tickets = []
    for i in range(1, n_rows + 1):
        # Distribución no uniforme: productos más caros generan menos tickets
        # (precio como proxy de calidad percibida)
        weights = [1 / (p["price"] ** 0.3) for p in products]
        product = random.choices(products, weights=weights, k=1)[0]
        tickets.append(generate_ticket(i, product))
    return tickets


def write_csv(tickets: list[dict], path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fieldnames = list(tickets[0].keys())
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(tickets)
    size_kb = os.path.getsize(path) / 1024
    print(f"[OK] Written: {path}")
    print(f"     Rows: {len(tickets)} | Size: {size_kb:.1f} KB")
    print(f"     Columns: {fieldnames}")


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Generate synthetic support tickets from FakeStore API")
    parser.add_argument("--rows", type=int, default=500,  help="Number of tickets to generate (default: 500)")
    parser.add_argument("--seed", type=int, default=42,   help="Random seed for reproducibility (default: 42)")
    parser.add_argument("--out",  type=str, default=OUTPUT_FILE, help="Output CSV path")
    args = parser.parse_args()

    random.seed(args.seed)

    print(f"[INFO] Generating {args.rows} tickets (seed={args.seed})")

    products = fetch_products()
    tickets  = generate_tickets(products, args.rows)
    write_csv(tickets, args.out)

    # ── Mini-stats ────────────────────────────────────────────────────────────
    from collections import Counter
    cats   = Counter(t["Category"] for t in tickets)
    status = Counter(t["Ticket Status"] for t in tickets)
    avg_sat = sum(t["Customer Satisfaction Rating"] for t in tickets) / len(tickets)

    print("\n── Ticket distribution by category ──")
    for cat, n in cats.most_common():
        bar = "█" * (n // 5)
        print(f"  {cat:<25} {n:>4}  {bar}")

    print("\n── Status distribution ──")
    for s, n in status.most_common():
        print(f"  {s:<20} {n:>4}")

    print(f"\n── Avg satisfaction: {avg_sat:.2f} / 5.0 ──")
    print(f"\n✅ Done → {args.out}")


if __name__ == "__main__":
    main()
