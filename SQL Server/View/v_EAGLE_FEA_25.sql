USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_25]    Script Date: 08/26/2014 13:37:12 ******/
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


CREATE VIEW [dbo].[v_EAGLE_FEA_25]
AS
    SELECT  AA.ProgramName ,
            AA.ComodityType ,
            25 AS Percentage ,
            AA.ParticipantAccountNumber ,
            AA.ParticipantName ,
            AA.DesignatedAccountNumber ,
            AA.ReferredAccountNumber ,
            AA.ReferredName ,
            AA.AppDate ,
            AA.ReferredCount ,
            AA.ReferredAccountStatus ,
            AA.ParticipantEMail ,
            AA.ParticipantPhone ,
            AA.ParticipantCity ,
            AA.ParticipantState ,
            AA.ParticipantZip
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing] AA
            WITH ( NOLOCK )
    INNER JOIN ( SELECT ZZ.DesignatedAccountNumber ,
                        ZZ.ProgramName
                 FROM   StreamInternal.dbo.[v_EAGLE_FEA_AssociateParticipantsReferredAccountListing] ZZ
                        WITH ( NOLOCK )
                 WHERE  ZZ.AppDate > '2014-02-21'
                        AND ZZ.ReferredAccountStatus = 'Active'
                 GROUP BY ZZ.DesignatedAccountNumber ,
                        ZZ.ProgramName
                 HAVING MAX(ReferredCount) > 4
                        AND MAX(ReferredCount) < 10
                        AND ZZ.ProgramName LIKE 'HWY2FDM%'
               ) ST ON AA.DesignatedAccountNumber = ST.DesignatedAccountNumber
                       AND AA.ProgramName = ST.ProgramName
    WHERE   AA.AppDate > '2014-02-21'
            AND AA.ReferredAccountStatus = 'Active'
    UNION
    SELECT  AA.ProgramName ,
            AA.ComodityType ,
            25 AS Percentage ,
            AA.ParticipantAccountNumber ,
            AA.ParticipantName ,
            AA.DesignatedAccountNumber ,
            AA.ReferredAccountNumber ,
            AA.ReferredName ,
            AA.AppDate ,
            AA.ReferredCount ,
            AA.ReferredAccountStatus ,
            AA.ParticipantEMail ,
            AA.ParticipantPhone ,
            AA.ParticipantCity ,
            AA.ParticipantState ,
            AA.ParticipantZip
    FROM    StreamInternal.dbo.[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing] AA
            WITH ( NOLOCK )
    INNER JOIN ( SELECT ZZ.DesignatedAccountNumber ,
                        ZZ.ProgramName
                 FROM   StreamInternal.dbo.[v_EAGLE_FEA_CustomerParticipantsReferredAccountListing] ZZ
                        WITH ( NOLOCK )
                 WHERE  ZZ.AppDate > '2014-02-21'
                        AND ZZ.ReferredAccountStatus = 'Active'
                 GROUP BY ZZ.DesignatedAccountNumber ,
                        ZZ.ProgramName
                 HAVING MAX(ReferredCount) > 4
                        AND MAX(ReferredCount) < 10
                        AND ZZ.ProgramName LIKE 'HWY2FDM%'
               ) ST ON AA.DesignatedAccountNumber = ST.DesignatedAccountNumber
                       AND AA.ProgramName = ST.ProgramName
    WHERE   AA.AppDate > '2014-02-21'
            AND AA.ReferredAccountStatus = 'Active' 














GO


