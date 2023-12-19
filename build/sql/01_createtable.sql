CREATE TABLE inventory.orders (id INTEGER PRIMARY KEY, order_date date, purchaser INTEGER, quantity INTEGER, product_id INTEGER)
GO
CREATE TABLE inventory.products (id INTEGER PRIMARY KEY, name VARCHAR(255), description VARCHAR(512), weight DECIMAL(9,3))
GO
CREATE TABLE inventory.customers (id INTEGER PRIMARY KEY, first_name VARCHAR(255), last_name VARCHAR(255), email VARCHAR(255))
GO
