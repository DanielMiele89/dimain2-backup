CREATE TABLE [MI].[SchemeMarginsAndTargets_OLD] (
    [ID]                          INT            IDENTITY (1, 1) NOT NULL,
    [PartnerID]                   INT            NULL,
    [PartnerGroupID]              INT            NULL,
    [RewardTargetUplift]          DECIMAL (6, 2) NULL,
    [ContractTargetUplift]        DECIMAL (5, 2) NULL,
    [ContractROI]                 DECIMAL (7, 2) NULL,
    [margin]                      DECIMAL (6, 2) NULL,
    [SchemeNotesCustomTargets]    VARCHAR (256)  NULL,
    [startdate]                   DATE           NULL,
    [IsNonCore]                   BIT            CONSTRAINT [DF_MI_SchemeMarginsAndTargets] DEFAULT ((0)) NOT NULL,
    [EndDate]                     DATE           NULL,
    [StartMonthID]                INT            NULL,
    [EndMonthID]                  INT            NULL,
    [VirtualPartnerID]            INT            NULL,
    [Reporting_ClientServicesRef] VARCHAR (10)   NULL,
    [MethodologyText]             NVARCHAR (600) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140731-192908]
    ON [MI].[SchemeMarginsAndTargets_OLD]([StartMonthID] ASC, [EndMonthID] ASC);


GO
CREATE NONCLUSTERED INDEX [NonClusteredIndex-20140617-105044]
    ON [MI].[SchemeMarginsAndTargets_OLD]([IsNonCore] ASC, [StartMonthID] ASC);


GO
CREATE NONCLUSTERED INDEX [PartnerID]
    ON [MI].[SchemeMarginsAndTargets_OLD]([PartnerID] ASC);

