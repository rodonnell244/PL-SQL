create or replace package marketing_consent_options_k
is

/*RO 26/02/18
marketing consent options Maintenance Form
grant execute on marketing_consent_options_k to asp3_user*/


	procedure nav_p
		(p_sid in number := 0
		,p_section in varchar2 := 'FRM'
		,p_code in varchar2 := null
		,p_url in varchar2 := 'e_agent_data.report_menus_k.nav_p'
		,p_description in varchar2 := null
		,p_linked_to in varchar2 := null
		,p_deleted in varchar2 := null
		,p_request in varchar2 := null
 		);

end marketing_consent_options_k;
/
create or replace package body marketing_consent_options_k
is

/*RO 26/02/18
marketing consent options Maintenance Form
grant execute on marketing_consent_options_k to asp3_user*/
	pv_sid number;
	pv_err_id number;
	
	procedure report_p
		(p_url in varchar2 
		)
	is
		cursor c1 is
		select * from marketing_consent_options_t order by description;
		
		type comm_t is table of t_communication_types.description%type index by t_communication_types.code%type;
		a_comm_type comm_t; 
	begin
	
		template_p(t => 'MAIN', h => 'Marketing Consent Options');
		
		for r in (select code, description 
				from t_communication_types 
				)
		loop
			a_comm_type(r.code) := r.description; 
		end loop;

		--menu bar
		menu_bar_k.menu_bar_open;
		menu_open(p_id => 'FileMenu', p_anchor => 'Return', p_display => 'Return', p_url => 'e_agent_data.marketing_consent_options_k.nav_p?p_sid=' || pv_sid || '&p_section=FRM&p_url=' || p_url);		
		menu_k.close_p(p_id => 'FileMenu');
		menu_bar_k.menu_bar_close;
				
		template_k.open_form_table_p(p_form_or_report => 'REPORT');
		template_k.open_inner_field_table_p;
		--report headings
		report_layout_k.col_headings;
		htp.p('<th align="left">Code</th>
			<th align="left">Description</th>
			<th align="left">Linked To</th>
			<th align="left">System Flag</th>
			<th align="left">Deleted</th>
		</tr>');

		--detail lines
		for crec in c1 loop
			htp.p('<tr class="row' || to_char(mod(c1%rowcount+1,2)+1) || '">');
			htp.p('<td align="left"><a href="e_agent_data.marketing_consent_options_k.nav_p?p_sid=' || pv_sid || '&p_section=FRM&p_url=' || p_url || '&p_code=' || crec.code || '">' || crec.code || '</a></td>');
			htp.p('<td align="left">' || crec.description || '</td>');
			if crec.linked_to is not null then
				htp.p('<td align="left">' || a_comm_type(crec.linked_to) || '</td>');
			else
				htp.p('<td align="left"></td>');
			end if;
			htp.p('<td align="center">' || crec.sys_flag || '</td>');
			if crec.deleted = 'Y' then	
				htp.p('<td align="center" class="mandatory">Yes</td>');
			else
				htp.p('<td align="center">No</td>');
			end if;
			htp.p('</tr>');
		end loop;

		template_k.close_inner_field_table_p;
		template_k.close_form_table_p;

		template_p('CLOSE');
	
	
	end report_p;
	
	procedure save_p(
		 p_code in varchar2 
		,p_description in varchar2 
		,p_linked_to in varchar2
		,p_deleted in varchar2 
		,p_request in varchar2
		,p_url in varchar2
	)
	is
	begin
		 if p_request = 'Insert' then
		 	insert into marketing_consent_options_t
				(code
				,deleted
				,description
				,linked_to
			) values
				(p_code
				,p_deleted
				,p_description
				,p_linked_to
			);
		 else
			update marketing_consent_options_t 
			set description = p_description,
				linked_to = p_linked_to,
				deleted = p_deleted
			where code = p_code;
			
		 end if;
		 
		 marketing_consent_options_k.nav_p(p_sid => pv_sid, p_section => 'FRM', p_code => p_code, p_url=> p_url);
	
	end save_p;
	
	procedure form_p(
		 p_code in varchar2
		,p_url in varchar2 
		)
	is
		crec marketing_consent_options_t%rowtype := null;
		
		type t_lov_rec is record(code varchar2(10), description varchar2(100));
		type t_lov_tab is table of t_lov_rec index by pls_integer;
		a_lov t_lov_tab;
	begin
		template_p(t => 'MAIN', h => 'Marketing Consent Options');	

	--menu bar
		menu_bar_k.menu_bar_open;
		menu_k.open_p(p_id => 'FileMenu', p_text => 'Return', p_url => p_url);
		menu_k.close_p(p_id => 'FileMenu');
		menu_open(p_id => 'FileMenu2', p_anchor => 'Find', p_display => 'Find', p_url => 'e_agent_data.marketing_consent_options_k.nav_p?p_sid=' || pv_sid || '&p_section=REPORT&p_url=' || p_url);
		menu_k.close_p(p_id => 'FileMenu2');
		menu_open(p_id => 'FileMenu3', p_anchor => 'Clear', p_display => 'Clear', p_url => 'e_agent_data.marketing_consent_options_k.nav_p?p_sid=' || pv_sid || '&p_section=FRM&p_url=' || p_url);
		menu_k.close_p(p_id => 'FileMenu3');
		menu_bar_k.menu_bar_close;
	
				
		htp.p('<table><tr><td valign="top">');
		--FORM
		htp.p('<form action="e_agent_data.marketing_consent_options_k.nav_p" method="post" name="com_form_but">');
		template_k.open_form_table_p;

	--get record
		if p_code is not null then
			select * into crec from marketing_consent_options_t where code = p_code;
		end if;

	--buttons
		template_k.open_button_table_p;
		if p_code is null then
			htp.p('<input name=p_request class=butwidth60 type=submit value="Insert" OnClick="return fCheckAll()">');
		else
			htp.p('<input name=p_request class=butwidth60 type=submit value="Update" OnClick="return fCheckAll()">');
		end if;
		template_k.close_button_table_p;

		template_k.split_form_table_p;
		template_k.open_inner_field_table_p;
	--hidden 
		htp.p('<input type=hidden name=p_sid value=' || pv_sid || '>');
		htp.p('<input type=hidden name=p_url value="' || p_url || '">');
		htp.p('<input type=hidden name=p_section value="SAVE">');
	
		htp.p('<td align=right class="mandatory">Code</td><td><input type=text name="p_code" maxlength=10 size=10 value="' || crec.code || '"></td></tr>');
		
		htp.p('<td align=right class="mandatory">Description</td><td><input type=text name="p_description" maxlength=50 size=50 value="' || crec.description || '"></td></tr>');

		--Foreign key to communication types so the system knows where to show this marketing preference
		htp.p('<tr><td valign=top align=right>Linked To</td>');
		htp.p('<td colspan=4><select id="p_linked_to" name="p_linked_to">');
		htp.p('<option value=""></option>');

		select t.code, t.description
		bulk collect into a_lov
		from t_communication_types t
		where nvl(t.deleted, 'N') = 'N'
		order by t.description;
		
		for ix in 1 .. a_lov.count loop
			if a_lov(ix).code = crec.linked_to then
				htp.p('<option selected value="' || a_lov(ix).code || '">' || a_lov(ix).description || ' (' || a_lov(ix).code || ')</option>');
			else
				htp.p('<option value="' || a_lov(ix).code || '">' || a_lov(ix).description || ' (' || a_lov(ix).code || ')</option>');
			end if;
		end loop;

		htp.p('</select></td></tr>');
		
		--deleted
		htp.p('<tr><td align=right>Deleted</td>');
		htp.p('<td><select name=p_deleted>');
		if crec.deleted = 'Y' then
			htp.p('<option value="N">No </option><option selected value="Y">Yes</option>');
		else
			htp.p('<option selected value="N"> </option><option value="Y">Yes</option>');
		end if;
		htp.p('</select></td></tr>');

		template_k.close_inner_field_table_p;
		template_k.close_form_table_p;
					
		htp.p('</form>');
		
		htp.p('<script type="text/javascript" language="JavaScript1.1">');

		htp.p('function fCheckAll() {');
		htp.p('	if (document.com_form_but.p_code.value == "") {alert("Code cannot be blank.");return false;}');
		htp.p('	if (document.com_form_but.p_description.value == "") {alert("Description cannot be blank.");return false;}');	

		htp.p('	return true;');
		htp.p('}');
		
		htp.p('</script>');

		template_p(t => 'CLOSE');

		
	
	end form_p;

	procedure nav_p
		(p_sid in number := 0
		,p_section in varchar2 := 'FRM'
		,p_code in varchar2 := null
		,p_url in varchar2 := 'e_agent_data.report_menus_k.nav_p'
		,p_description in varchar2 := null
		,p_linked_to in varchar2 := null
		,p_deleted in varchar2 := null
		,p_request in varchar2 := null
 		)
	is
	begin
		pv_sid := p_sid;
		if p_section = 'FRM' then

			form_p(p_code => p_code
				,p_url => p_url
				);
		elsif p_section = 'SAVE' then
			save_p(
				 p_code => p_code
				,p_description => p_description
				,p_linked_to => p_linked_to
				,p_deleted => p_deleted
				,p_request => p_request
				,p_url => p_url
			);
		elsif p_section = 'REPORT' then 
			report_p(
				 p_url => p_url
			);
		end if;
		
		exception when others then 
			pv_err_id := error_k.set_f(pv_sid);
			rollback; 
			error_k.get_p(p_sid=>pv_sid, p_err_id => pv_err_id);

	end nav_p;

end marketing_consent_options_k;
/
