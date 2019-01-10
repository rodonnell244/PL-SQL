create or replace function blob_to_clob
	(blob_in in blob
	)
	return clob
as
	v_clob clob;
	v_varchar varchar2(32767);
	v_start number := 1;
	v_buffer number := 32767;
begin
	dbms_lob.createtemporary(v_clob, true);

	for i in 1..ceil(dbms_lob.getlength(blob_in) / v_buffer) loop

		v_varchar := utl_raw.cast_to_varchar2(dbms_lob.substr(blob_in, v_buffer, v_start));

		dbms_lob.writeappend(v_clob, length(v_varchar), v_varchar);

		v_start := v_start + v_buffer;
	end loop;

	return v_clob;
end blob_to_clob;
/
