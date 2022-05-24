CREATE TABLE [Staging].[SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus] (
    [FanID]                 INT          NOT NULL,
    [POC_Customer]          VARCHAR (27) NOT NULL,
    [CustomerType]          VARCHAR (3)  NOT NULL,
    [POCCustomers]          INT          NOT NULL,
    [CustomerJourneyStatus] VARCHAR (24) NULL,
    [LapsFlag]              VARCHAR (11) NOT NULL,
    [EmailEngaged]          INT          NULL,
    [POC_EmailEngaged]      INT          NOT NULL,
    [NonPOC_EmailEngaged]   INT          NOT NULL
);

