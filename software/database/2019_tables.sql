DROP TABLE IF EXISTS gm2trigger_analog_a6_2019 ;
CREATE TABLE IF NOT EXISTS gm2trigger_analog_a6_2019 (id INT NOT NULL,channel INT,sequence INT, pulse_index INT, delay INT, width INT, enabled INT, time TIMESTAMP, PRIMARY KEY (id,channel,sequence,pulse_index));
GRANT ALL PRIVILEGES ON gm2trigger_analog_a6_2019 TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_analog_a6_2019 to gm2_writer;
GRANT SELECT ON gm2trigger_analog_a6_2019 to gm2_reader;

ALTER SEQUENCE gm2trigger_analog_a6_2019_id_seq RESTART WITH 1;
DROP SEQUENCE IF EXISTS gm2trigger_analog_a6_2019_id_seq;
CREATE SEQUENCE gm2trigger_analog_a6_2019_id_seq;
GRANT ALL PRIVILEGES ON gm2trigger_analog_a6_2019_id_seq TO gm2_admin;
GRANT USAGE ON gm2trigger_analog_a6_2019_id_seq to gm2_writer;
GRANT SELECT ON gm2trigger_analog_a6_2019_id_seq to gm2_reader;

DROP TABLE IF EXISTS gm2trigger_analog_t9_2019 ;
CREATE TABLE IF NOT EXISTS gm2trigger_analog_t9_2019 (id INT NOT NULL,channel INT,sequence INT, delay INT, enabled INT, global_width INT, time TIMESTAMP, PRIMARY KEY (id,channel,sequence));
GRANT ALL PRIVILEGES ON gm2trigger_analog_t9_2019 TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_analog_t9_2019 to gm2_writer;
GRANT SELECT ON gm2trigger_analog_t9_2019 to gm2_reader;

ALTER SEQUENCE gm2trigger_analog_t9_2019_id_seq RESTART WITH 1;
DROP SEQUENCE IF EXISTS gm2trigger_analog_t9_2019_id_seq;
CREATE SEQUENCE gm2trigger_analog_t9_2019_id_seq;
GRANT ALL PRIVILEGES ON gm2trigger_analog_t9_2019_id_seq TO gm2_admin;
GRANT USAGE ON gm2trigger_analog_t9_2019_id_seq to gm2_writer;
GRANT SELECT ON gm2trigger_analog_t9_2019_id_seq to gm2_reader;

DROP TABLE IF EXISTS gm2trigger_ttc_analog_pulse_2019 ;
CREATE TABLE IF NOT EXISTS gm2trigger_ttc_analog_pulse_2019 (delay int, width INT, id INT NOT NULL );
GRANT ALL PRIVILEGES ON gm2trigger_ttc_analog_pulse_2019 TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_ttc_analog_pulse_2019 to gm2_writer;
GRANT SELECT ON gm2trigger_ttc_analog_pulse_2019 to gm2_reader;
ALTER SEQUENCE gm2trigger_ttc_analog_pulse_2019_id_seq RESTART WITH 1;
DROP SEQUENCE IF EXISTS gm2trigger_ttc_analog_pulse_2019_id_seq;
CREATE SEQUENCE gm2trigger_ttc_analog_pulse_2019_id_seq;
GRANT ALL PRIVILEGES ON gm2trigger_ttc_analog_pulse_2019_id_seq TO gm2_admin;
GRANT USAGE ON gm2trigger_ttc_analog_pulse_2019_id_seq to gm2_writer;
GRANT SELECT ON gm2trigger_ttc_analog_pulse_2019_id_seq to gm2_reader;


DROP TABLE IF EXISTS gm2trigger_settings_2019 ;
CREATE TABLE IF NOT EXISTS gm2trigger_settings_2019 (valid_from TIMESTAMP NOT NULL,ttc_id INT NOT NULL,analog_a6_id INT NOT NULL, analog_t9_id INT NOT NULL, analog_ttc_id INT NOT NULL);
GRANT ALL PRIVILEGES ON gm2trigger_settings_2019 TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_settings_2019 to gm2_writer;
GRANT SELECT ON gm2trigger_settings_2019 to gm2_reader;

DROP TABLE IF EXISTS gm2trigger_descriptions_2019 ;
CREATE TABLE IF NOT EXISTS gm2trigger_descriptions_2019 (id_name VARCHAR(16) NOT NULL, id INT NOT NULL, description VARCHAR(64) NOT NULL);
GRANT ALL PRIVILEGES ON gm2trigger_descriptions_2019 TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_descriptions_2019 to gm2_writer;
GRANT SELECT ON gm2trigger_descriptions_2019 to gm2_reader;


DROP TABLE IF EXISTS gm2trigger_ttc_2019 ;
CREATE TABLE IF NOT EXISTS gm2trigger_ttc_2019 (id INT NOT NULL,sequence INT,pulse_index INT, gap INT, type INT, time TIMESTAMP, PRIMARY KEY (id,sequence,pulse_index));
GRANT ALL PRIVILEGES ON gm2trigger_ttc_2019 TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_ttc_2019 to gm2_writer;
GRANT SELECT ON gm2trigger_ttc_2019 to gm2_reader;

DROP SEQUENCE IF EXISTS gm2trigger_ttc_2019_id_seq;
CREATE SEQUENCE gm2trigger_ttc_2019_id_seq;
GRANT ALL PRIVILEGES ON gm2trigger_ttc_2019_id_seq TO gm2_admin;
GRANT USAGE ON gm2trigger_ttc_2019_id_seq to gm2_writer;
GRANT SELECT ON gm2trigger_ttc_2019_id_seq to gm2_reader;

DROP TABLE IF EXISTS gm2trigger_status ;
CREATE TABLE IF NOT EXISTS gm2trigger_status (midas_expt VARCHAR(16) NOT NULL,run INT NOT NULL,num_triggers INT NOT NULL, num_errors INT NOT NULL,avg_deadtime REAL NOT NULL, time TIMESTAMP NOT NULL);
GRANT ALL PRIVILEGES ON gm2trigger_status TO gm2_admin;
GRANT SELECT, INSERT, UPDATE ON gm2trigger_status to gm2_writer;
GRANT SELECT ON gm2trigger_status to gm2_reader;


