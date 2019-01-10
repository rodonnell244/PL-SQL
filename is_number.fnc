create or replace function is_number
	(p_input in varchar2
	)
	return varchar2
is
/* */
	v_number number;
begin
	v_number := to_number(p_input);

	if v_number is null then
		return 'N';
	else
		return 'Y';
	end if;
exception
	when value_error then
		return 'N';
end is_number;
/
