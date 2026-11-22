-- Create only the HOPE operational tables.
-- The existing application audit_log has a different schema and is preserved.
BEGIN;
SET LOCAL search_path = public, pg_temp;

DO $$
DECLARE
    relation_count INTEGER;
    table_count INTEGER;
    missing_columns TEXT;
BEGIN
    SELECT count(*),
           count(*) FILTER (WHERE c.relkind IN ('r', 'p'))
      INTO relation_count, table_count
      FROM pg_class AS c
      JOIN pg_namespace AS n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public'
       AND c.relname = ANY (ARRAY[
           'employee', 'department', 'job', 'jobhistory', 'customer',
           'sales', 'product', 'salesdetail', 'payment', 'pricehist'
       ]::text[]);

    IF relation_count NOT IN (0, 10) OR table_count <> relation_count THEN
        RAISE EXCEPTION
            'HOPE operational migration stopped: partial or conflicting public relations exist. Inspect the schema before applying.';
    END IF;

    IF relation_count = 10 THEN
        WITH required_columns(table_name, column_name) AS (
            VALUES
            ('employee', 'empno'), ('employee', 'lastname'), ('employee', 'firstname'),
            ('employee', 'gender'), ('employee', 'birthdate'), ('employee', 'hiredate'),
            ('employee', 'sepdate'),
            ('department', 'deptcode'), ('department', 'deptname'),
            ('job', 'jobcode'), ('job', 'jobdesc'),
            ('jobhistory', 'empno'), ('jobhistory', 'jobcode'), ('jobhistory', 'effdate'),
            ('jobhistory', 'salary'), ('jobhistory', 'deptcode'),
            ('customer', 'custno'), ('customer', 'custname'), ('customer', 'address'),
            ('customer', 'payterm'),
            ('sales', 'transno'), ('sales', 'salesdate'), ('sales', 'custno'), ('sales', 'empno'),
            ('product', 'prodcode'), ('product', 'description'), ('product', 'unit'),
            ('salesdetail', 'transno'), ('salesdetail', 'prodcode'), ('salesdetail', 'quantity'),
            ('payment', 'orno'), ('payment', 'paydate'), ('payment', 'amount'), ('payment', 'transno'),
            ('pricehist', 'effdate'), ('pricehist', 'prodcode'), ('pricehist', 'unitprice')
        )
        SELECT string_agg(r.table_name || '.' || r.column_name, ', ' ORDER BY r.table_name, r.column_name)
          INTO missing_columns
          FROM required_columns AS r
          LEFT JOIN information_schema.columns AS c
            ON c.table_schema = 'public'
           AND c.table_name = r.table_name
           AND c.column_name = r.column_name
         WHERE c.column_name IS NULL;

        IF missing_columns IS NOT NULL THEN
            RAISE EXCEPTION
                'HOPE operational migration stopped: missing required source columns: %',
                missing_columns;
        END IF;
    END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS employee (
    empno VARCHAR(5) NOT NULL PRIMARY KEY,
    lastname VARCHAR(15),
    firstname VARCHAR(15),
    gender CHAR(1) CONSTRAINT gender_ck CHECK (gender IN ('M', 'F')),
    birthdate DATE,
    hiredate DATE,
    sepDate DATE
);

CREATE TABLE IF NOT EXISTS department (
    deptCode VARCHAR(3) NOT NULL PRIMARY KEY,
    deptName VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS job (
    jobCode VARCHAR(4) NOT NULL PRIMARY KEY,
    jobDesc VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS jobHistory (
    empNo VARCHAR(5) NOT NULL REFERENCES employee,
    jobCode VARCHAR(4) NOT NULL REFERENCES job,
    effDate DATE NOT NULL,
    salary DECIMAL(10, 2) CONSTRAINT salary_ck CHECK (salary >= 0.0),
    deptCode VARCHAR(4),
    PRIMARY KEY (empNo, jobCode, effDate),
    FOREIGN KEY (deptCode) REFERENCES department
);

CREATE TABLE IF NOT EXISTS customer (
    custno VARCHAR(5) NOT NULL PRIMARY KEY,
    custname VARCHAR(20),
    address VARCHAR(50),
    payterm VARCHAR(3) CONSTRAINT pay_ck CHECK (payterm IN ('COD', '30D', '45D'))
);

CREATE TABLE IF NOT EXISTS sales (
    transNo VARCHAR(8) NOT NULL PRIMARY KEY,
    salesDate DATE,
    custNo VARCHAR(5) REFERENCES customer,
    empNo VARCHAR(5) REFERENCES employee
);

CREATE TABLE IF NOT EXISTS product (
    prodCode VARCHAR(6) NOT NULL PRIMARY KEY,
    description VARCHAR(30),
    unit VARCHAR(3) CONSTRAINT unit_ck CHECK (unit IN ('pc', 'ea', 'mtr', 'pkg', 'ltr'))
);

CREATE TABLE IF NOT EXISTS salesDetail (
    transNo VARCHAR(8) NOT NULL REFERENCES sales,
    prodCode VARCHAR(6) NOT NULL REFERENCES product,
    quantity DECIMAL(10, 2) CONSTRAINT quantity_ck CHECK (quantity >= 0.0),
    PRIMARY KEY (transNo, prodCode)
);

CREATE TABLE IF NOT EXISTS payment (
    orNo VARCHAR(8) NOT NULL PRIMARY KEY,
    payDate DATE,
    amount DECIMAL(10, 2),
    transno VARCHAR(8) REFERENCES sales
);

CREATE TABLE IF NOT EXISTS priceHist (
    effDate DATE NOT NULL,
    prodCode VARCHAR(6) NOT NULL REFERENCES product,
    unitPrice DECIMAL(10, 2) CONSTRAINT unitP_ck CHECK (unitPrice > 0),
    PRIMARY KEY (effDate, prodCode)
);

ALTER TABLE employee ENABLE ROW LEVEL SECURITY;
ALTER TABLE department ENABLE ROW LEVEL SECURITY;
ALTER TABLE job ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobHistory ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE product ENABLE ROW LEVEL SECURITY;
ALTER TABLE salesDetail ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment ENABLE ROW LEVEL SECURITY;
ALTER TABLE priceHist ENABLE ROW LEVEL SECURITY;

COMMIT;
