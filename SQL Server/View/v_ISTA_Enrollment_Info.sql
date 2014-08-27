USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_Enrollment_Info]    Script Date: 08/26/2014 15:08:38 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
7/22/2013				Darren Williams						Initial Release [v_ISTA_Enrollment_Info] .
															Purpose of this view is to consistently capture 
															Enrollment and any info associated to each enrollment.
						   
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/



CREATE VIEW [dbo].[v_ISTA_Enrollment_Info]
AS
    SELECT DISTINCT
            p.PremNo ,
            p.PremType ,
            ldc.LDCShortName ,
            ca.ClientAccountNo ,
            c.FEIN ,
            p.LDCID ,
            ecp.EsiId AS 'EnrollmentPremiseNumber' ,
            ec.EnrollCustID ,
            ec.CustomerAccountNumber AS 'EnrollmentCustomerNumber' ,
            c.CustType ,
            c.CustStatus ,
            p.PremStatus ,
            p.StatusID ,
            es.EnrollStatusID ,
            es.Description ,
            ec.CustName AS 'Enrollment Name' ,
            ec.Last4SSN AS 'Last4SSN' ,
            ec.CreateDate AS 'EnrollmentDate' ,
            ec.SuspendDate AS 'EnrollmentSuspendDate' ,
            c.CreateDate AS 'CustomerCreateDate' ,
            ecp.Addr1 AS 'EnrollmentAddr1' ,
            ecp.Addr2 AS 'EnrollmentAddr2' ,
            ecp.City AS 'EnrollmentCity' ,
            ecp.State AS 'EnrollmentState' ,
            ecp.Zip AS 'EnrollmentZip'
    FROM    Stream.dbo.EnrollCustomer ec
    LEFT JOIN Stream.dbo.EnrollCustomerPremise ecp ON ecp.EnrollCustID = ec.EnrollCustID
    LEFT JOIN Stream.dbo.enrollstatus AS es ON es.enrollstatusid = ec.EnrollStatusID
    LEFT JOIN Stream.dbo.Customer c ON c.CustID = ec.CsrCustID
    LEFT JOIN Stream.dbo.CustomerAdditionalInfo ca ON ca.CustID = c.CustID
    LEFT JOIN Stream.dbo.Premise p ON p.CustID = c.CustID
    LEFT JOIN Stream.dbo.LDCLookup ldc ON p.LDCID = ldc.LDCID
    GROUP BY p.PremNo ,
            p.PremType ,
            ldc.LDCShortName ,
            ca.ClientAccountNo ,
            c.FEIN ,
            p.LDCID ,
            ecp.EsiId ,
            ec.EnrollCustID ,
            ec.CustomerAccountNumber ,
            c.CustType ,
            c.CustStatus ,
            p.PremStatus ,
            p.StatusID ,
            es.EnrollStatusID ,
            es.Description ,
            ec.CustName ,
            ec.Last4SSN ,
            ec.CreateDate ,
            ec.SuspendDate ,
            c.CreateDate ,
            ecp.Addr1 ,
            ecp.Addr2 ,
            ecp.City ,
            ecp.State ,
            ecp.Zip 





GO


