CREATE TABLE [MI].[CAPPartnerRef] (
    [ID]                SMALLINT     IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT          NOT NULL,
    [ClientServicesRef] VARCHAR (10) NOT NULL,
    CONSTRAINT [PK_MI_CAPPartnerRef] PRIMARY KEY CLUSTERED ([ID] ASC)
);

