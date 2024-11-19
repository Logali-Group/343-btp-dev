@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'HCM'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity Z_C_HC343_MASTER
  provider contract transactional_query
  as projection on z_r_hc343_master
{
      @ObjectModel.text.element: ['EmployeeName']
  key EmployeeNumber,
      EmployeeName,
      EmployeeDepartment,
      EmployeeStatus,
      JobTitle,
      StartDate,
      EndDate,
      Email,
      @ObjectModel.text.element: ['ManagerName']
      ManagerNumber,
      ManagerName,
      ManagerDepartment,
      CreatedOn,
      @Semantics.user.createdBy: true
      CreatedBy,
      ChangedOn,
      @Semantics.user.lastChangedBy: true
      ChangedBy
}
