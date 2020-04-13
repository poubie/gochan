-- Gochan master template for new database script
-- Contains macros in the form [curlybrace open]macro text[curlybrace close]
-- Macros are substituted by build_initdb.py to the supported database files. Must not contain extra spaces
-- Versioning numbering goes by whole numbers. Upgrade script migrate existing databases between versions
-- Database version: 1

CREATE TABLE DBPREFIXdatabase_version(
	version INT NOT NULL
);

INSERT INTO DBPREFIXdatabase_version(version)
VALUES(1);

CREATE TABLE DBPREFIXsections(
	id {serial pk},
	name TEXT NOT NULL,
	abbreviation TEXT NOT NULL,
	position SMALLINT NOT NULL,
	hidden BOOL NOT NULL,
	UNIQUE(position)
);

CREATE TABLE DBPREFIXboards(
	id {serial pk},
	section_id {fk to serial} NOT NULL,
	uri TEXT NOT NULL,
	dir VARCHAR(45) NOT NULL,
	navbar_position SMALLINT NOT NULL,
	title VARCHAR(45) NOT NULL,
	subtitle VARCHAR(64) NOT NULL,
	description VARCHAR(64) NOT NULL,
	max_file_size INT NOT NULL,
	max_threads SMALLINT NOT NULL,
	default_style VARCHAR(45) NOT NULL,
	locked BOOL NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	anonymous_name VARCHAR(45) NOT NULL DEFAULT 'Anonymous',
	force_anonymous BOOL NOT NULL,
	autosage_after SMALLINT NOT NULL,
	no_images_after SMALLINT NOT NULL,
	max_message_length SMALLINT NOT NULL,
	min_message_length SMALLINT NOT NULL,
	allow_embeds BOOL NOT NULL,
	redictect_to_thread BOOL NOT NULL,
	require_file BOOL NOT NULL,
	enable_catalog BOOL NOT NULL,
	FOREIGN KEY(section_id) REFERENCES DBPREFIXsections(id),
	UNIQUE(dir),
	UNIQUE(uri),
	UNIQUE(navbar_position)
);

CREATE TABLE DBPREFIXthreads(
	id {serial pk},
	board_id {fk to serial} NOT NULL,
	locked BOOL NOT NULL DEFAULT FALSE,
	stickied BOOL NOT NULL DEFAULT FALSE,
	anchored BOOL NOT NULL DEFAULT FALSE,
	cyclical BOOL NOT NULL DEFAULT FALSE,
	last_bump TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	deleted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	is_deleted BOOL NOT NULL DEFAULT FALSE,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id)
);

CREATE INDEX thread_deleted_index ON DBPREFIXthreads(is_deleted);

CREATE TABLE DBPREFIXposts(
	id {serial pk},
	thread_id {fk to serial} NOT NULL,
	is_top_post BOOL NOT NULL DEFAULT FALSE,
	ip INT NOT NULL,
	created_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	name VARCHAR(50) NOT NULL DEFAULT '',
	tripcode VARCHAR(10) NOT NULL DEFAULT '',
	is_role_signature BOOL NOT NULL DEFAULT FALSE,
	email VARCHAR(50) NOT NULL DEFAULT '',
	subject VARCHAR(100) NOT NULL DEFAULT '',
	message TEXT NOT NULL,
	message_raw TEXT NOT NULL,
	password TEXT NOT NULL,
	deleted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	is_deleted BOOL NOT NULL DEFAULT FALSE,
	banned_message TEXT,
	FOREIGN KEY(thread_id) REFERENCES DBPREFIXthreads(id)
);

CREATE INDEX top_post_index ON DBPREFIXposts(is_top_post);

CREATE TABLE DBPREFIXfiles(
	id {serial pk},
	post_id {fk to serial} NOT NULL,
	file_order INT NOT NULL,
	original_filename VARCHAR(255) NOT NULL,
	filename VARCHAR(45) NOT NULL,
	checksum INT NOT NULL,
	file_size INT NOT NULL,
	is_spoilered BOOL NOT NULL,
	thumbnail_width INT NOT NULL,
	thumbnail_height INT NOT NULL,
	FOREIGN KEY(post_id) REFERENCES DBPREFIXposts(id),
	UNIQUE(post_id, file_order)
);

CREATE TABLE DBPREFIXstaff(
	id {serial pk},
	username VARCHAR(45) NOT NULL,
	password_checksum VARCHAR(120) NOT NULL,
	global_rank INT,
	added_on TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	last_login TIMESTAMP NOT NULL,
	is_active BOOL NOT NULL DEFAULT TRUE,
	UNIQUE(username)
);

CREATE TABLE DBPREFIXsessions(
	id {serial pk},
	staff_id {fk to serial} NOT NULL,
	expires TIMESTAMP NOT NULL,
	data VARCHAR(45) NOT NULL,
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXboard_staff(
	board_id {fk to serial} NOT NULL,
	staff_id {fk to serial} NOT NULL,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXannouncements(
	id {serial pk},
	staff_id {fk to serial} NOT NULL,
	subject VARCHAR(45) NOT NULL,
	message TEXT NOT NULL,
	timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXip_ban(
	id {serial pk},
	staff_id {fk to serial} NOT NULL,
	board_id {fk to serial} NOT NULL,
	banned_for_post_id {fk to serial} NOT NULL,
	copy_post_text TEXT NOT NULL,
	is_active BOOL NOT NULL,
	ip INT NOT NULL,
	issued_at TIMESTAMP NOT NULL,
	appeal_at TIMESTAMP NOT NULL,
	expires_at TIMESTAMP NOT NULL,
	permanent BOOL NOT NULL,
	staff_note VARCHAR(255) NOT NULL,
	message TEXT NOT NULL,
	can_appeal BOOL NOT NULL,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id),
	FOREIGN KEY(banned_for_post_id) REFERENCES DBPREFIXposts(id)
);

CREATE TABLE DBPREFIXip_ban_audit(
	ip_ban_id {fk to serial} NOT NULL,
	timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	staff_id {fk to serial} NOT NULL,
	is_active BOOL NOT NULL,
	expires_at TIMESTAMP NOT NULL,
	appeal_at TIMESTAMP NOT NULL,
	permanent BOOL NOT NULL,
	staff_note VARCHAR(255) NOT NULL,
	message TEXT NOT NULL,
	can_appeal BOOL NOT NULL,
	PRIMARY KEY(ip_ban_id, timestamp),
	FOREIGN KEY(ip_ban_id) REFERENCES DBPREFIXip_ban(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXip_ban_appeals(
	id {serial pk},
	staff_id {fk to serial},
	ip_ban_id {fk to serial} NOT NULL,
	appeal_text TEXT NOT NULL,
	staff_response TEXT,
	is_denied BOOL NOT NULL,
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id),
	FOREIGN KEY(ip_ban_id) REFERENCES DBPREFIXip_ban(id)
);

CREATE TABLE DBPREFIXip_ban_appeals_audit(
	appeal_id {fk to serial} NOT NULL,
	timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	staff_id {fk to serial},
	appeal_text TEXT NOT NULL,
	staff_response TEXT,
	is_denied BOOL NOT NULL,
	PRIMARY KEY(appeal_id, timestamp),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id),
	FOREIGN KEY(appeal_id) REFERENCES DBPREFIXip_ban_appeals(id)
);

CREATE TABLE DBPREFIXreports(
	id {serial pk}, 
	handled_by_staff_id {fk to serial},
	post_id {fk to serial} NOT NULL,
	ip INT NOT NULL,
	reason TEXT NOT NULL,
	is_cleared BOOL NOT NULL,
	FOREIGN KEY(handled_by_staff_id) REFERENCES DBPREFIXstaff(id),
	FOREIGN KEY(post_id) REFERENCES DBPREFIXposts(id)
);

CREATE TABLE DBPREFIXreports_audit(
	report_id {fk to serial} NOT NULL,
	timestamp TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	handled_by_staff_id {fk to serial},
	is_cleared BOOL NOT NULL,
	FOREIGN KEY(handled_by_staff_id) REFERENCES DBPREFIXstaff(id),
	FOREIGN KEY(report_id) REFERENCES DBPREFIXreports(id)
);

CREATE TABLE DBPREFIXfilename_ban(
	id {serial pk},
	board_id {fk to serial},
	staff_id {fk to serial} NOT NULL,
	staff_note VARCHAR(255) NOT NULL,
	issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	filename VARCHAR(255) NOT NULL,
	is_regex BOOL NOT NULL,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXusername_ban(
	id {serial pk},
	board_id {fk to serial},
	staff_id {fk to serial} NOT NULL,
	staff_note VARCHAR(255) NOT NULL,
	issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	username VARCHAR(255) NOT NULL,
	is_regex BOOL NOT NULL,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXfile_ban(
	id {serial pk},
	board_id {fk to serial},
	staff_id {fk to serial} NOT NULL,
	staff_note VARCHAR(255) NOT NULL,
	issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	checksum INT NOT NULL,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);

CREATE TABLE DBPREFIXwordfilters(
	id {serial pk},
	board_id {fk to serial},
	staff_id {fk to serial} NOT NULL,
	staff_note VARCHAR(255) NOT NULL,
	issued_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
	search VARCHAR(75) NOT NULL CHECK (search <> ''),
	is_regex BOOL NOT NULL,
	change_to VARCHAR(75) NOT NULL,
	FOREIGN KEY(board_id) REFERENCES DBPREFIXboards(id),
	FOREIGN KEY(staff_id) REFERENCES DBPREFIXstaff(id)
);