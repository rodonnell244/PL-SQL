create or replace package tenancy_reports_k
is

	type fallen_rec is record (
		id 		     t_contracts.id%type,
		property         varchar2(2000), 
		contract_type    t_contract_types.description%type,
		site             varchar2(2000),
		start_date       t_contracts.start_date%type,
		completed_date   t_contracts.completed_date%type,
		tenancy_type     t_tenancy_types.description%type,
		completed_flag   t_contracts.completed_flag%type,
		completed_reason t_close_reasons.description%type,
		rent_amount      t_contracts.rent_amount%type,
		commission       number,
		neg              varchar2(500),
		sold_by          varchar2(500),
		landlord         varchar2(500),
		tenant           varchar2(500),
		deposit_balance  varchar2(500),
		tenant_balance   varchar2(500),
		last_note        varchar2(2000)
	);
	type fallen_tab is table of fallen_rec;
end tenancy_reports_k;
/

create or replace package body tenancy_reports_k
is
	type cur_typ is ref cursor;
	pv_sid number := 0;

	type ctyp_t is table of t_contract_types.description%type index by t_contract_types.code%type;
	a_ctyp ctyp_t;

	type ttyp_t is table of t_tenancy_types.description%type index by t_tenancy_types.code%type;
	a_ttyp ttyp_t;

	type emp_t is table of t_employees.full_name%type index by varchar2(100);
	a_employees emp_t;

	procedure pop_lookups_p
	is
	begin
		for r in ( select code, description from t_contract_types ) loop
			a_ctyp(r.code) := r.description;
		end loop;
		for r in ( select code, description from t_tenancy_types ) loop
			a_ttyp(r.code) := r.description;
		end loop;
		for r in (select e.id, e.full_name from t_employees e ) loop
			a_employees(r.id) := r.full_name; 		
		end loop;
	end pop_lookups_p;

	function fallen_f (
			p_site_codes in varchar2,
			p_start_date in varchar2,
			p_end_date   in varchar2,
			p_neg        in varchar2,
			p_sold_by    in varchar2
		)
		return fallen_tab pipelined
		is
			v_row fallen_rec;
			
			type query_rec_t is record (
				id 		     t_contracts.id%type,
				contract_type    t_contracts.ctyp_code%type,
				site             varchar2(2000),
				start_date       t_contracts.start_date%type,
				completed_date   t_contracts.completed_date%type,
				tenancy_type     t_contracts.tenancy_type%type,
				completed_flag   t_contracts.completed_flag%type,
				completed_reason t_close_reasons.description%type,
				empl_id          varchar2(2000),
				sold_by          varchar2(2000),
				rent_amount      t_contracts.rent_amount%type,
				last_note        varchar2(2000)
			);
			
			type query_tab_t is table of query_rec_t index by pls_integer;
			v_records query_tab_t;
			
			c1 cur_typ;
			
			v_query	   varchar2(8000);
			v_close_reason varchar2(200) := null;
		begin
			pop_lookups_p;

			v_close_reason := ',' || parameters_utl_k.get_setting_f('UNDO_LET_CLOSE_REASON', 'PULL_OUT', null) || ',';
			v_query := '
				select /* + ordered index(con con_act_com_ctyp_site_i) index(crea crea_pk) use_nl(con,crea) */
					con.id as "Contract",
					con.ctyp_code,
					con.site_code,
					con.start_date,
					con.completed_date,
					con.tenancy_type,
					con.completed_flag,
					crea.description as "Reason",
					con.empl_id,
					con.sold_by,
					con.rent_amount,
					null as "Last Note"
				from  t_contracts con, t_close_reasons crea
				where crea.code = con.crea_code
				  and con.ctyp_code in (select code from t_contract_types where prospective = ''N'' and department = ''RL'' and nvl(deleted,''N'') = ''N'')
				  and con.active_flag = ''N''
				  and con.completed_flag = ''Y''
				  and nvl(con.deleted, ''N'') = ''N''
				  and con.deleted is null
				  and instr(:v_close_reason, con.crea_code) > 0
				  and security_k.has_site_f(p_sid => 0, p_user => ''' || utl_misc_k.pv_user || ''', p_site => con.site_code) = ''Y'' 
			' || pc_cr;
		    
			if p_site_Codes is not null then 
				v_query := v_query || ' and con.site_code in (select column_value from table(utl_formatting_k.string_to_rows(:p_site_codes, '':''))) ';
			else 
				v_query := v_query || ' and :p_site_codes is null ';
				if security_k.full_access_f(user) = 'N' then
					v_query := v_query || '	and exists (select /*+ index(es emp_site_pk)*/ 1 from t_employee_sites es where es.emp_login_name = v(''APP_USER'') and es.site_code = con.site_code) ';
				end if;
			end if;
			
			if p_neg is not null then 
				v_query := v_query || ' and instr('':'' || nvl(:p_neg, ''0'') || '':'', '':'' || nvl(con.empl_id, ''0'') || '':'') > 0 ' || pc_cr;
			else 
				v_query := v_query || ' and :p_neg is null ' || pc_cr;
			end if;
			
			if  p_sold_by is not null then 
				v_query := v_query || ' and instr('':'' || nvl(:p_sold_by, ''0'') || '':'', '':'' || nvl(con.sold_by, ''0'') || '':'') > 0 ' || pc_cr;
			else
				v_query := v_query || ' and :p_sold_by is null ' || pc_cr;
			end if;
			
			if p_start_date is not null then 
				v_query := v_query || ' and con.start_Date >= nvl(to_date(:p_start_date, ''dd/mm/yyyy''), ''01-jan-1901'') ' || pc_cr;
			else
				v_query := v_query || ' and :p_start_date is null ' || pc_cr;
			end if;
			
			if p_end_date is not null then 
				v_query := v_query || ' and con.start_Date <=  nvl(to_date(:p_end_date, ''dd/mm/yyyy''), ''01-jan-2051'') ' || pc_cr;
			else
				v_query := v_query || ' and :p_end_date is null ' || pc_cr;
			end if;
			
			
			/*
			v_query2 := replace(v_query,  ':p_site_codes',   '''' || p_site_codes   || '''');
			v_query2 := replace(v_query,  ':p_neg',          '''' || p_neg          || '''');
			v_query2 := replace(v_query,  ':p_sold_by',      '''' || p_sold_by      || '''');
			v_query2 := replace(v_query2, ':p_start_date',   '''' || p_start_date   || '''');
			v_query2 := replace(v_query2, ':p_end_date',     '''' || p_end_date     || '''');
			v_query2 := replace(v_query2, ':v_close_reason', '''' || v_close_reason || '''');
			htp.comment(v_query2);
			*/
			
			
			open c1 for v_query 
				using  v_close_reason,p_site_codes, p_neg, p_sold_by,p_start_date, p_end_date;
			fetch c1 bulk collect into v_records;
			close c1;
			
			for i in 1..v_records.count loop
	-- Clear v_row
				v_row             := null;
	-- Populate v_row...
				v_row.id               := v_records(i).id;
				v_row.site             := utl_lookup_k.site_name_f(v_records(i).site);
				v_row.property         := utl_addr_name_comm_k.address_prop_f(v_records(i).id, '1T');
				v_row.start_date       := v_records(i).start_date;
				v_row.completed_date   := v_records(i).completed_date;    
				v_row.completed_flag   := v_records(i).completed_flag;    
				v_row.completed_reason := v_records(i).completed_reason;
				v_row.commission       := to_number(apex_reports_k.sales_total_f(v_records(i).id, 'G'));
				
				if a_employees.exists(v_records(i).empl_id) then
					v_row.neg      := a_employees(v_records(i).empl_id);
				end if;

				if a_employees.exists(v_records(i).sold_by) then
					v_row.sold_by      := a_employees(v_records(i).sold_by);
				end if;

				v_row.landlord         := utl_addr_name_comm_k.name_add_f('l', '<br>', v_records(i).id, 'C');
				v_row.tenant           := utl_addr_name_comm_k.name_add_f('t', '<br>', v_records(i).id, 'C');

				if a_ctyp.exists(v_records(i).contract_type) then
					v_row.contract_type             := a_ctyp(v_records(i).contract_type);
				end if;
				
				if a_ttyp.exists(v_records(i).tenancy_type) then
					v_row.tenancy_type              := a_ttyp(v_records(i).tenancy_type); 
				end if;

				v_row.deposit_balance  := num2char(acc_bal_f(pv_sid, acc_id_f(pv_sid, 'D', v_records(i).id)),'5U');
				v_row.tenant_balance   := num2char(acc_bal_f(pv_sid, acc_id_f(pv_sid, 'T', v_records(i).id)),'5U');
				
				select /*+index(vt vtex_table_name_i)*/ max(vt.TEXT) 
				v_row.last_note
				from t_variable_text vt 
				where vt.REF_TABLE_NAME = 'T_CONTRACTS' 
				and vt.REF_TABLE_ID = v_records(i).id;
				        		    
				pipe row (v_row);
			end loop;
	end fallen_f;
end tenancy_reports_k;
/
