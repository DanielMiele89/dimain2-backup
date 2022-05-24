CREATE TABLE [Email].[OPE_PartnerExclusions] (
    [ID]              INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]       INT           NOT NULL,
    [ExclusionReason] VARCHAR (250) NULL,
    [StartDate]       DATE          NOT NULL,
    [EndDate]         DATE          NULL
);

