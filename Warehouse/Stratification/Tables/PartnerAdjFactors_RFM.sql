CREATE TABLE [Stratification].[PartnerAdjFactors_RFM] (
    [PartnerGroupID]          INT        NULL,
    [PartnerID]               INT        NULL,
    [MonthID]                 INT        NULL,
    [ActivatedLowCount]       INT        NULL,
    [ControlLowCount]         INT        NULL,
    [ActivatedMediumCount]    INT        NULL,
    [ControlMediumCount]      INT        NULL,
    [ActivatedHighCount]      INT        NULL,
    [ControlHighCount]        INT        NULL,
    [ActivatedLowSpenders]    INT        NULL,
    [ControlLowSpenders]      INT        NULL,
    [ActivatedMediumSpenders] INT        NULL,
    [ControlMediumSpenders]   INT        NULL,
    [ActivatedHighSpenders]   INT        NULL,
    [ControlHighSpenders]     INT        NULL,
    [AdjFactor_LowSPC]        FLOAT (53) NULL,
    [AdjFactor_MediumSPC]     FLOAT (53) NULL,
    [AdjFactor_HighSPC]       FLOAT (53) NULL
);

