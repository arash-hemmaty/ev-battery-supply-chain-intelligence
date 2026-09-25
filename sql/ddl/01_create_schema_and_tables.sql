-- ============================================================
-- EV Battery Supply Chain Intelligence
-- DDL: Schema and Tables
-- ============================================================
-- This file creates the complete physical data model.
-- Run order: execute the whole file top-to-bottom.
-- ============================================================

DROP SCHEMA IF EXISTS ev CASCADE;
CREATE SCHEMA ev;

-- ============================================
-- DIMENSIONS
-- ============================================

CREATE TABLE ev.dim_unit (
    unit_id         SERIAL PRIMARY KEY,
    unit_code       VARCHAR(20)  NOT NULL UNIQUE,
    unit_name       VARCHAR(50)  NOT NULL,
    unit_type       VARCHAR(30)  NOT NULL,
    base_unit_code  VARCHAR(20),
    notes           TEXT
);

CREATE TABLE ev.dim_region (
    region_id         SERIAL PRIMARY KEY,
    region_code       VARCHAR(20)  NOT NULL UNIQUE,
    region_name       VARCHAR(100) NOT NULL,
    parent_region_id  INT REFERENCES ev.dim_region(region_id)
);

CREATE TABLE ev.dim_stage (
    stage_id     SERIAL PRIMARY KEY,
    stage_code   VARCHAR(30)  NOT NULL UNIQUE,
    stage_name   VARCHAR(100) NOT NULL,
    chain_side   VARCHAR(20)  NOT NULL,
    stage_order  SMALLINT     NOT NULL
);

CREATE TABLE ev.dim_source (
    source_id         SERIAL PRIMARY KEY,
    source_code       VARCHAR(40)  NOT NULL UNIQUE,
    source_name       VARCHAR(200) NOT NULL,
    source_type       VARCHAR(30),
    source_url        TEXT,
    publication_year  SMALLINT
);

CREATE TABLE ev.dim_date (
    date_id    SERIAL PRIMARY KEY,
    year       SMALLINT NOT NULL UNIQUE,
    is_latest  BOOLEAN  DEFAULT FALSE
);

CREATE TABLE ev.dim_chemistry (
    chemistry_id   SERIAL PRIMARY KEY,
    chemistry_code VARCHAR(20)  NOT NULL UNIQUE,
    chemistry_name VARCHAR(100) NOT NULL,
    notes          TEXT
);

CREATE TABLE ev.dim_country (
    country_id     SERIAL PRIMARY KEY,
    country_code   CHAR(3)      NOT NULL UNIQUE,
    country_name   VARCHAR(100) NOT NULL,
    region_id      INT REFERENCES ev.dim_region(region_id),
    is_active      BOOLEAN DEFAULT TRUE,
    notes          TEXT
);

CREATE TABLE ev.dim_product_material (
    product_material_id  SERIAL PRIMARY KEY,
    code                 VARCHAR(40)  NOT NULL UNIQUE,
    name                 VARCHAR(150) NOT NULL,
    entity_type          VARCHAR(30)  NOT NULL,
    material_group       VARCHAR(40),
    stage_id             INT REFERENCES ev.dim_stage(stage_id),
    default_unit_id      INT REFERENCES ev.dim_unit(unit_id),
    chemistry_id         INT REFERENCES ev.dim_chemistry(chemistry_id),
    notes                TEXT
);

CREATE TABLE ev.dim_company (
    company_id     SERIAL PRIMARY KEY,
    company_code   VARCHAR(40)  NOT NULL UNIQUE,
    company_name   VARCHAR(200) NOT NULL,
    country_id     INT REFERENCES ev.dim_country(country_id),
    company_type   VARCHAR(40),
    notes          TEXT
);

CREATE TABLE ev.dim_source_term_mapping (
    mapping_id           SERIAL PRIMARY KEY,
    source_id            INT NOT NULL REFERENCES ev.dim_source(source_id),
    source_term          VARCHAR(200) NOT NULL,
    product_material_id  INT NOT NULL REFERENCES ev.dim_product_material(product_material_id),
    notes                TEXT,
    CONSTRAINT uq_source_term UNIQUE (source_id, source_term)
);

-- ============================================
-- FACTS
-- ============================================

CREATE TABLE ev.fact_production (
    production_id       BIGSERIAL PRIMARY KEY,
    country_id          INT NOT NULL REFERENCES ev.dim_country(country_id),
    product_material_id INT NOT NULL REFERENCES ev.dim_product_material(product_material_id),
    stage_id            INT NOT NULL REFERENCES ev.dim_stage(stage_id),
    date_id             INT NOT NULL REFERENCES ev.dim_date(date_id),
    unit_id             INT NOT NULL REFERENCES ev.dim_unit(unit_id),
    source_id           INT NOT NULL REFERENCES ev.dim_source(source_id),
    quantity            NUMERIC(20,4) NOT NULL CHECK (quantity >= 0),
    notes               TEXT,
    CONSTRAINT uq_fact_production
        UNIQUE (country_id, product_material_id, stage_id, date_id, source_id)
);

CREATE INDEX ix_fp_date    ON ev.fact_production(date_id);
CREATE INDEX ix_fp_country ON ev.fact_production(country_id);
CREATE INDEX ix_fp_product ON ev.fact_production(product_material_id);

CREATE TABLE ev.fact_trade (
    trade_id            BIGSERIAL PRIMARY KEY,
    exporter_country_id INT NOT NULL REFERENCES ev.dim_country(country_id),
    importer_country_id INT NOT NULL REFERENCES ev.dim_country(country_id),
    product_material_id INT NOT NULL REFERENCES ev.dim_product_material(product_material_id),
    date_id             INT NOT NULL REFERENCES ev.dim_date(date_id),
    unit_id             INT NOT NULL REFERENCES ev.dim_unit(unit_id),
    source_id           INT NOT NULL REFERENCES ev.dim_source(source_id),
    hs_code             VARCHAR(10),
    trade_quantity      NUMERIC(20,4) CHECK (trade_quantity >= 0),
    trade_value_usd     NUMERIC(20,4) CHECK (trade_value_usd >= 0),
    notes               TEXT,
    CONSTRAINT uq_fact_trade
        UNIQUE (exporter_country_id, importer_country_id, product_material_id,
                date_id, hs_code, source_id),
    CONSTRAINT chk_fact_trade_diff_countries
        CHECK (exporter_country_id <> importer_country_id)
);

CREATE INDEX ix_ft_date_exp ON ev.fact_trade(date_id, exporter_country_id);
CREATE INDEX ix_ft_date_imp ON ev.fact_trade(date_id, importer_country_id);
CREATE INDEX ix_ft_product  ON ev.fact_trade(product_material_id);

CREATE TABLE ev.fact_capacity (
    capacity_id         BIGSERIAL PRIMARY KEY,
    country_id          INT NOT NULL REFERENCES ev.dim_country(country_id),
    company_id          INT REFERENCES ev.dim_company(company_id),
    product_material_id INT NOT NULL REFERENCES ev.dim_product_material(product_material_id),
    date_id             INT NOT NULL REFERENCES ev.dim_date(date_id),
    unit_id             INT NOT NULL REFERENCES ev.dim_unit(unit_id),
    source_id           INT NOT NULL REFERENCES ev.dim_source(source_id),
    capacity_quantity   NUMERIC(20,4) NOT NULL CHECK (capacity_quantity >= 0),
    status              VARCHAR(20) DEFAULT 'operational',
    notes               TEXT
);

CREATE UNIQUE INDEX uq_fact_capacity
    ON ev.fact_capacity (country_id, COALESCE(company_id, 0), product_material_id,
                         date_id, status, source_id);

CREATE INDEX ix_fc_date    ON ev.fact_capacity(date_id);
CREATE INDEX ix_fc_country ON ev.fact_capacity(country_id);