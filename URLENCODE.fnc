create or replace function URLENCODE
 (P_URL in varchar2
 )
 return varchar2
 is

	vUrl varchar2(32767);
	vHexVal number;
begin
	if p_url is not null then
		for i in 1 .. length(p_url) loop
			vHexVal := ascii(substr(p_url,i,1));
			if(vHexVal<48 or (vHexVal>57 and vHexVal<65) or (vHexVal>90 and vHexVal<97) or vHexVal>122) then
				vUrl := vUrl || '%' || ToHex(vHexVal);
			else
				vUrl := vUrl || substr(p_url,i,1);
			end if;
		end loop;
	end if;
	return(vUrl);
end;

 
 
/
