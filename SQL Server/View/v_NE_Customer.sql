USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_NE_Customer]    Script Date: 08/26/2014 15:11:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
7/18/2013				Steve Nelson						Initial Release [v_NE_Customer] .
															Purpose of this view is to consistently capture customer count and all necessary info associated to each customer.
						  
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_NE_Customer]
AS
    SELECT  Premise.PremID ,
            Premise.CustID ,
            Premise.PremNo AS LDCNo ,
            Customer.CustNo ,
            Customer.CustType AS PremiseType ,
            Premise.PremType AS Commodity ,
            LDCLookup.LDCShortName AS LDC ,
            Customer.CustName ,
            Customer.LastName ,
            Customer.FirstName ,
            Address.Addr1 ,
            Address.Addr2 ,
            Address.City ,
            Address.State ,
            PremiseStatus.Status AS Status ,
            AccountsReceivable.BalDue AS AmtDue
    FROM    ( ( ( ( Stream.dbo.Premise Premise
                    LEFT OUTER JOIN Stream.dbo.Customer Customer ON ( Premise.CustID = Customer.CustID )
                  )
                  LEFT OUTER JOIN Stream.dbo.Address Address ON ( Premise.AddrID = Address.AddrID )
                )
                LEFT OUTER JOIN Stream.dbo.PremiseStatus PremiseStatus ON ( Premise.StatusID = PremiseStatus.PremiseStatusID )
              )
              LEFT OUTER JOIN Stream.dbo.LDCLookup LDCLookup ON ( Premise.LDCID = LDCLookup.LDCID )
            )
    LEFT OUTER JOIN Stream.dbo.AccountsReceivable AccountsReceivable ON ( Customer.AcctsRecID = AccountsReceivable.AcctsRecID )

GO


