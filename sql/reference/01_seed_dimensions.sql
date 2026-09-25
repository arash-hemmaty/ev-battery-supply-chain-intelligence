-- ============================================================
-- Reference Data Seed
-- ============================================================
-- Populates all dimensions with reference data.
-- Run AFTER 01_create_schema_and_tables.sql
-- ============================================================

-- ----- dim_unit -----
INSERT INTO ev.dim_unit (unit_code, unit_name, unit_type, base_unit_code, notes) VALUES
('T',    'Metric Tonne',    'mass',     'T',    'Standard mass unit.'),
('KG',   'Kilogram',        'mass',     'T',    '1000 KG = 1 T.'),
('GWH',  'Gigawatt-hour',   'energy',   'GWH',  'Battery capacity unit.'),
('MWH',  'Megawatt-hour',   'energy',   'GWH',  '1000 MWH = 1 GWH.'),
('USD',  'US Dollar',       'currency', 'USD',  'Monetary value.'),
('UNIT', 'Number of Units', 'count',    'UNIT', 'Discrete units.'),
('PCT',  'Percentage',      'ratio',    'PCT',  'Derived share metrics.');

-- ----- dim_region -----
INSERT INTO ev.dim_region (region_code, region_name, parent_region_id) VALUES
('WORLD',  'World',              NULL),
('ASIA',   'Asia',               1),
('EUROPE', 'Europe',             1),
('NA',     'North America',      1),
('SA',     'South America',      1),
('AFRICA', 'Africa',             1),
('OCEANIA','Oceania',            1),
('EASIA',  'East Asia',          2),
('SEASIA', 'Southeast Asia',     2),
('SASIA',  'South Asia',         2),
('CASIA',  'Central Asia',       2),
('WASIA',  'West Asia',          2);

-- ----- dim_stage -----
INSERT INTO ev.dim_stage (stage_code, stage_name, chain_side, stage_order) VALUES
('GRAPHITE_MINING',        'Graphite Mining',                  'anode',      1),
('GRAPHITE_BENEFICIATION', 'Graphite Beneficiation',           'anode',      2),
('SPHERICAL_GRAPHITE',     'Spherical Graphite Production',    'anode',      3),
('GRAPHITE_PURIFICATION',  'Graphite Purification',            'anode',      4),
('GRAPHITE_COATING',       'Graphite Coating',                 'anode',      5),
('AAM_PRODUCTION',         'Anode Active Material Production', 'anode',      6),
('LI_CARBONATE',           'Lithium Carbonate Production',     'cathode',    7),
('IRON_PHOSPHATE',         'Iron Phosphate Precursor',         'cathode',    8),
('LFP_CAM',                'LFP Cathode Active Material',      'cathode',    9),
('CATHODE_ELECTRODE',      'Cathode Electrode Production',     'cathode',   10),
('CELL_MANUFACTURING',     'Cell Manufacturing',               'assembly',  11),
('MODULE_PACK',            'Module / Pack Assembly',           'assembly',  12),
('EV_ASSEMBLY',            'EV Assembly',                      'assembly',  13),
('RECYCLING',              'Recycling / Recovery',             'recycling', 14);

-- ----- dim_chemistry -----
INSERT INTO ev.dim_chemistry (chemistry_code, chemistry_name, notes) VALUES
('LFP',        'Lithium Iron Phosphate',  'LiFePO4. Dominant in China.'),
('NMC',        'Nickel Manganese Cobalt', 'LiNiMnCoO2. Common in EU/NA.'),
('NCA',        'Nickel Cobalt Aluminum',  'Tesla / Panasonic.'),
('LMO',        'Lithium Manganese Oxide', 'Less common in modern EV.'),
('SODIUM_ION', 'Sodium-Ion',              'Emerging chemistry.');

-- ----- dim_source -----
INSERT INTO ev.dim_source (source_code, source_name, source_type, source_url, publication_year) VALUES
('USGS_MCS',     'USGS Mineral Commodity Summaries',     'government',        'https://www.usgs.gov/centers/national-minerals-information-center/mineral-commodity-summaries', 2025),
('USGS_MYB',     'USGS Minerals Yearbook',               'government',        'https://www.usgs.gov/centers/national-minerals-information-center/minerals-yearbook-metals-and-minerals', 2024),
('IEA_GCMO',     'IEA Global Critical Minerals Outlook', 'international_org', 'https://www.iea.org/reports/global-critical-minerals-outlook-2025', 2025),
('IEA_GEVO',     'IEA Global EV Outlook',                'international_org', 'https://www.iea.org/reports/global-ev-outlook-2025', 2025),
('UN_COMTRADE',  'UN Comtrade Database',                 'international_org', 'https://comtradeplus.un.org/', NULL),
('BNEF',         'BloombergNEF',                         'industry',          'https://about.bnef.com/', NULL),
('SNE_RESEARCH', 'SNE Research',                         'industry',          'https://www.sneresearch.com/en/', NULL),
('BENCHMARK_MIN','Benchmark Mineral Intelligence',       'industry',          'https://benchmarkminerals.com/', NULL);

-- ----- dim_date -----
INSERT INTO ev.dim_date (year, is_latest) VALUES
(2015, FALSE), (2016, FALSE), (2017, FALSE), (2018, FALSE),
(2019, FALSE), (2020, FALSE), (2021, FALSE), (2022, FALSE),
(2023, FALSE), (2024, FALSE), (2025, FALSE), (2026, TRUE);

-- ----- dim_country -----
INSERT INTO ev.dim_country (country_code, country_name, region_id) VALUES
('CHN', 'China',                8),
('JPN', 'Japan',                8),
('KOR', 'South Korea',          8),
('TWN', 'Taiwan',               8),
('MNG', 'Mongolia',             8),
('VNM', 'Vietnam',              9),
('THA', 'Thailand',             9),
('IDN', 'Indonesia',            9),
('MYS', 'Malaysia',             9),
('PHL', 'Philippines',          9),
('SGP', 'Singapore',            9),
('IND', 'India',                10),
('PAK', 'Pakistan',             10),
('BGD', 'Bangladesh',           10),
('KAZ', 'Kazakhstan',           11),
('UZB', 'Uzbekistan',           11),
('TUR', 'Turkey',               12),
('SAU', 'Saudi Arabia',         12),
('ARE', 'United Arab Emirates', 12),
('ISR', 'Israel',               12),
('IRN', 'Iran',                 12),
('DEU', 'Germany',              3),
('FRA', 'France',               3),
('GBR', 'United Kingdom',       3),
('ITA', 'Italy',                3),
('ESP', 'Spain',                3),
('POL', 'Poland',               3),
('HUN', 'Hungary',              3),
('NOR', 'Norway',               3),
('SWE', 'Sweden',               3),
('FIN', 'Finland',              3),
('CZE', 'Czechia',              3),
('AUT', 'Austria',              3),
('BEL', 'Belgium',              3),
('NLD', 'Netherlands',          3),
('PRT', 'Portugal',             3),
('ROU', 'Romania',              3),
('SVK', 'Slovakia',             3),
('SRB', 'Serbia',               3),
('USA', 'United States',        4),
('CAN', 'Canada',               4),
('MEX', 'Mexico',               4),
('BRA', 'Brazil',               5),
('ARG', 'Argentina',            5),
('CHL', 'Chile',                5),
('PER', 'Peru',                 5),
('BOL', 'Bolivia',              5),
('ZAF', 'South Africa',         6),
('MOZ', 'Mozambique',           6),
('MDG', 'Madagascar',           6),
('COD', 'DR Congo',             6),
('ZMB', 'Zambia',               6),
('TZA', 'Tanzania',             6),
('NAM', 'Namibia',              6),
('ZWE', 'Zimbabwe',             6),
('EGY', 'Egypt',                6),
('MAR', 'Morocco',              6),
('GHA', 'Ghana',                6),
('NGA', 'Nigeria',              6),
('ETH', 'Ethiopia',             6),
('KEN', 'Kenya',                6),
('AUS', 'Australia',            7),
('NZL', 'New Zealand',          7);

-- ----- dim_product_material -----
INSERT INTO ev.dim_product_material
(code, name, entity_type, material_group, stage_id, default_unit_id, chemistry_id, notes) VALUES
('NAT_GRAPHITE',  'Natural Graphite',              'raw_material', 'graphite',  1, 1, NULL, 'Raw graphite ore.'),
('GRAPHITE_CONC', 'Graphite Concentrate',          'intermediate', 'graphite',  2, 1, NULL, 'Beneficiated, ~90-95% C.'),
('SPHERICAL_GR',  'Spherical Graphite',            'intermediate', 'graphite',  3, 1, NULL, 'Mechanically shaped.'),
('PURIFIED_SG',   'Purified Spherical Graphite',   'intermediate', 'graphite',  4, 1, NULL, '99.95%+ C.'),
('COATED_SG',     'Coated Spherical Graphite',     'intermediate', 'graphite',  5, 1, NULL, 'Pitch or carbon coated.'),
('AAM',           'Anode Active Material',         'intermediate', 'graphite',  6, 1, NULL, 'Ready for electrode.'),
('LI_CARBONATE',  'Lithium Carbonate',             'raw_material', 'lithium',   7, 1, NULL, 'Li2CO3.'),
('IRON_PHOSPHATE','Iron Phosphate',                'intermediate', 'phosphate', 8, 1, NULL, 'FePO4 precursor.'),
('LFP_CAM',       'LFP Cathode Active Material',   'component',    'lfp',       9, 1, 1,    'LiFePO4 CAM.'),
('CATHODE_ELEC',  'Cathode Electrode',             'component',    'lfp',      10, 1, 1,    'Coated cathode.'),
('CELL',          'Battery Cell',                  'component',    'battery',  11, 3, 1,    'Li-ion cell.'),
('MODULE',        'Battery Module',                'component',    'battery',  12, 3, 1,    'Module of cells.'),
('PACK',          'Battery Pack',                  'component',    'battery',  12, 3, 1,    'EV battery pack.'),
('EV',            'Electric Vehicle',              'end_product',  'vehicle',  13, 6, NULL, 'Finished EV.'),
('REC_GRAPHITE',  'Recycled Graphite',             'raw_material', 'graphite', 14, 1, NULL, 'Secondary graphite.'),
('LI_METAL',      'Lithium (raw)',                 'raw_material', 'lithium',   7, 1, NULL, 'Raw lithium (Phase 2).'),
('NICKEL',        'Nickel',                        'raw_material', 'nickel',    7, 1, NULL, 'For NMC (Phase 2).'),
('COBALT',        'Cobalt',                        'raw_material', 'cobalt',    7, 1, NULL, 'For NMC (Phase 2).'),
('NMC_CAM',       'NMC Cathode Active Material',   'component',    'nmc',       9, 1, 2,    'NMC CAM (Phase 2).');

-- ----- dim_company -----
INSERT INTO ev.dim_company (company_code, company_name, country_id, company_type, notes) VALUES
('CATL',       'Contemporary Amperex Technology Co. Limited', (SELECT country_id FROM ev.dim_country WHERE country_code='CHN'), 'cell_maker', 'Largest EV battery maker. LFP dominant.'),
('BYD',        'BYD Company',                                 (SELECT country_id FROM ev.dim_country WHERE country_code='CHN'), 'cell_maker', 'Vertically integrated. Blade Battery LFP.'),
('LGES',       'LG Energy Solution',                          (SELECT country_id FROM ev.dim_country WHERE country_code='KOR'), 'cell_maker', 'NMC focus, expanding LFP.'),
('PANASONIC',  'Panasonic Energy',                            (SELECT country_id FROM ev.dim_country WHERE country_code='JPN'), 'cell_maker', 'Tesla supplier. NCA/NMC.'),
('SAMSUNG_SDI','Samsung SDI',                                 (SELECT country_id FROM ev.dim_country WHERE country_code='KOR'), 'cell_maker', 'NMC, prismatic.'),
('SK_ON',      'SK On',                                       (SELECT country_id FROM ev.dim_country WHERE country_code='KOR'), 'cell_maker', 'NMC focus.'),
('EVE',        'EVE Energy',                                  (SELECT country_id FROM ev.dim_country WHERE country_code='CHN'), 'cell_maker', 'Major LFP producer.'),
('CALB',       'CALB Group',                                  (SELECT country_id FROM ev.dim_country WHERE country_code='CHN'), 'cell_maker', 'LFP + NMC.'),
('GOTION',     'Gotion High-Tech',                            (SELECT country_id FROM ev.dim_country WHERE country_code='CHN'), 'cell_maker', 'LFP focus, global.'),
('TESLA',      'Tesla, Inc.',                                 (SELECT country_id FROM ev.dim_country WHERE country_code='USA'), 'oem',        'EV maker with in-house cells.');