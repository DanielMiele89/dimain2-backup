CREATE TABLE [Relational].[RedemptionCodeType] (
    [CodeTypeID]        INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT          NULL,
    [Description]       VARCHAR (50) NOT NULL,
    [MaximumDailyIssue] SMALLINT     NULL,
    PRIMARY KEY CLUSTERED ([CodeTypeID] ASC)
);

