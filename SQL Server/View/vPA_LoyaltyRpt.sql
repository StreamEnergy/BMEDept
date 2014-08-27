USE [StreamInternal]
GO

/****** Object:  View [dbo].[vPA_LoyaltyRpt]    Script Date: 08/26/2014 13:19:05 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description


08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


ALTER VIEW [dbo].[vPA_LoyaltyRpt]
AS
    SELECT  c.CustNo ,
            ec.CustomerAccountNumber ,
            ecp.EsiId AS UtilityAccountNumber ,
            ss.SaleSourceDescription AS ChannelPartner ,
            c.FirstName ,
            c.LastName ,
            a.HomePhone ,
            a.OtherPhone ,
            a.WorkPhone ,
            a.FaxPhone ,
            a.PhoneExtension ,
            a.Addr1 AS BillingAddr1 ,
            a.Addr2 AS BillingAddr2 ,
            a.City AS BillingCity ,
            a.State AS BillingState ,
            a.Zip AS BillingZip ,
            c.CreditScore AS CreditScore ,
            a.Email ,
            ec.IgniteAccountNumber ,
            rt.RateTransitionID AS ContractID ,
            rt.SwitchDate AS ContractStartDate ,
            CASE WHEN rt.SoldDate > GETDATE() THEN 1
                 ELSE 0
            END AS PendingNewContract ,
            rt.SoldDate AS ContractEffectiveDate ,
            rd.ExpirationDate AS ContractExpirationDate ,
            p.BeginServiceDate AS ServicePeriodStartDate ,
            p.EndServiceDate ,
            t.MONTHs AS ContractTermLength ,
            d.PriceDescription AS ProductType ,
            rd.RateAmt AS ContractRate , --This will be filled in for fixed price products
 --rir.IndexRate, --for variable products the rate will be here
            l.LDCName AS Utility ,
            pa.Addr1 AS PremiseAddr1 ,
            pa.Addr2 AS PremiseAddr2 ,
            pa.City AS PremiseCity ,
            pa.State AS PremiseState ,
            pa.Zip AS PremiseZip ,
            p.PremType AS Commodity ,
            c.CustType AS PremiseType ,
            '' AS HUD ,
            p.EndServiceDate AS ExpectedDropDate ,
            c.CustID ,
            p.PremNo ,
            ss.salesourcedescription ,
            rd.EffectiveDate ,
            rd.Active ,
            rt.StatusID ,
            rt.enddate ,
            d.ProductCode ,
            ps.PremiseStatusID ,
            ps.status ,
            d.TermsId
    FROM    stream.dbo.Customer c
    LEFT JOIN stream.dbo.Premise p ON p.CustID = c.CustID
    LEFT JOIN stream.dbo.RateDetail rd ON rd.RateID = c.RateID --and rd.Active = 1 and isnull(rd.ExpirationDate, '1/1/2099') >= GETDATE()
    LEFT JOIN stream.dbo.RateTransition rt ON rd.RateTransitionId = rt.RateTransitionID/*rt.CustID = c.CustID*/ --and isnull(rt.EndDate,'1/1/2099') >= GETDATE() and rt.StatusID in (1,2) --pending or active
    LEFT JOIN stream.dbo.Product d ON d.RateID = rt.RateID
    LEFT JOIN stream.dbo.RateIndexRange rir ON rir.RateIndexTypeID = rd.FixedCapRate
                                               AND GETDATE() BETWEEN rir.DateFrom AND rir.DateTo -- there are multiple prices, you need to specify for which date
    LEFT JOIN stream.dbo.EnrollCustomer ec ON ec.CsrCustID = c.CustID
    LEFT JOIN stream.dbo.EnrollCustomerPremise ecp ON ecp.EnrollCustID = ec.EnrollCustID
    LEFT JOIN stream.dbo.LDCLookup l ON l.LDCID = p.LDCID
    LEFT JOIN stream.dbo.PremiseStatus ps ON p.StatusID = ps.PremiseStatusID
    LEFT JOIN stream.dbo.terms t ON t.termsid = d.termsid
    LEFT JOIN stream.dbo.salesource AS ss ON ss.salesourceid = ec.salessourceid
    LEFT JOIN stream.dbo.Address a ON c.MailAddrId = a.AddrID
    LEFT JOIN stream.dbo.Address pa ON p.AddrID = pa.AddrID
--where ec.CustomerAccountNumber='3000006395'


GO


