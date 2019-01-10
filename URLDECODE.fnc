create or replace function URLDECODE
 (p_url in varchar2
 )
 return varchar2
 is

	vUrl varchar2(32767);
	vAscii number;
	i number := 1;
begin
	while i <= LENGTH(p_url) loop
		vAscii := ASCII(SUBSTR(p_url,i,1));

	   /* if we find a % in the string we need to decode the hex value that follows */
		if vAscii = 37 then
			vUrl := vUrl||CHR(HexToBin(SUBSTR(p_url,i+1,2)));
			i := i + 3;
		else
			vUrl := vUrl || SUBSTR(p_url,i,1);
			i := i + 1;
		end if;
	end loop;

	return(vUrl);
end;


 
 
/
