

SELECT  VendorCustomerNumber
      , 'Name' = [FirstName] + ' ' + [LastName]
      , 'Address' = [Address1] + ' ' + [Address2]
      , [City]
      , [State]
      , [ZipCode]
      , Email
      , PrimaryPhone
      , CustomerStatus
      , EnrollDate
      , CASE WHEN ProductCode = 'seidcrit01'
             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
             WHEN ProductCode = 'seidcrit02'
             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
             WHEN ProductCode = 'seidcr01'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM)'
             WHEN ProductCode = 'seidcr02'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM) - Waive First Month Fee'
             WHEN ProductCode = 'seidit02'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,Tech) - Waive First Month Fee'
             WHEN ProductCode = 'seid01'
             THEN 'Silver HomeLife Services: ID Theft (ID)'
             WHEN ProductCode = 'seid02'
             THEN 'Silver HomeLife Services: ID Theft (ID) - Waive First Month Fee'
             WHEN ProductCode = 'seidcrit01'
             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
             WHEN ProductCode = 'seidcrit02'
             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
             WHEN ProductCode = 'seidcr01'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM)'
             WHEN ProductCode = 'seidcr02'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,CM) - Waive First Month Fee'
             WHEN ProductCode = 'secrit02'
             THEN 'Gold HomeLife Services: 2 Bundle (Tech, CM) - Waive First Month Fee'
             WHEN ProductCode = 'seidit01'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,IT)'
             WHEN ProductCode = 'secrit01'
             THEN 'Gold HomeLife Services: 2 Bundle (CM, IT)'
             WHEN ProductCode = 'secr01'
             THEN 'Silver HomeLife Services: Credit Monitoring (CM)'
             WHEN ProductCode = 'secr02'
             THEN 'Silver HomeLife Services: Credit Monitoring (CM) - Waive First Month Fee'
             WHEN ProductCode = 'seidcrit01'
             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM)'
             WHEN ProductCode = 'seidcrit02'
             THEN 'Platinum HomeLife Services: 3 Bundle (ID, Tech, CM) - Waive First Month Fee'
             WHEN ProductCode = 'seidit02'
             THEN 'Gold HomeLife Services: 2 Bundle (ID,Tech) - Waive First Month Fee'
             WHEN ProductCode = 'secrit02'
             THEN 'Gold HomeLife Services: 2 Bundle (Tech, CM) - Waive First Month Fee'
             WHEN ProductCode = 'seit01'
             THEN 'Silver HomeLife Services: Tech Support (Tech)'
             WHEN ProductCode = 'seit02'
             THEN 'Silver HomeLife Services: Tech Support (Tech) - Waive First Month Fee'
        END AS ProductCode
      , 'CancelDate' = MAX(CancelDate)
FROM    dbo.HLS_Customers_Data
WHERE   CustomerStatus = 'Cancelled'
        AND CancelDate IS NOT NULL
        --AND VendorCustomerNumber = '214100881'
GROUP BY VendorCustomerNumber
      , [FirstName] + ' ' + [LastName]
      , [Address1] + ' ' + [Address2]
      , [City]
      , [State]
      , [ZipCode]
      , Email
      , PrimaryPhone
      , CustomerStatus
      , EnrollDate
      , ProductCode
      --HAVING MAX(Renew_DT)> GETDATE()-10
	
--WHERE   
ORDER BY CancelDate DESC

SELECT  *
FROM    dbo.HLS_Customers_Data
WHERE   VendorCustomerNumber = '214217955'
--IS NOT NULL-- = 'Cancelled'
