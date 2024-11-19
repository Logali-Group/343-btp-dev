@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HC Master'
@Metadata.ignorePropagatedAnnotations: true
define root view entity z_r_hc343_master
  as select from zhc343_master
{
      @ObjectModel.text.element: ['EmployeeName']
  key e_number       as EmployeeNumber,
      e_name         as EmployeeName,
      e_department   as EmployeeDepartment,
      status         as EmployeeStatus,
      job_title      as JobTitle,
      start_date     as StartDate,
      end_date       as EndDate,
      email          as Email,
      @ObjectModel.text.element: ['ManagerName']
      m_number       as ManagerNumber,
      m_name         as ManagerName,
      m_department   as ManagerDepartment,
      crea_date_time as CreatedOn,
      @Semantics.user.createdBy: true
      crea_uname     as CreatedBy,
      lchg_date_time as ChangedOn,
      @Semantics.user.lastChangedBy: true
      lchg_uname     as ChangedBy
}
