CREATE TABLE [Staging].[OPEPartnerConflict] (
    [PartnerID]     INT     NOT NULL,
    [RuleID]        TINYINT NULL,
    [RNumber_Value] TINYINT NULL,
    [RNumber_Type]  TINYINT NULL,
    [LiveRule]      BIT     NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC)
);

