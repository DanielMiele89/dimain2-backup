CREATE TABLE [MI].[CustomerActivationPeriod_Archive] (
    [ID]              INT  IDENTITY (1, 1) NOT NULL,
    [FanID]           INT  NOT NULL,
    [ActivationStart] DATE NOT NULL,
    [ActivationEnd]   DATE NULL,
    [AddedDate]       DATE NULL,
    [UpdatedDate]     DATE NULL,
    [ArchiveDate]     DATE CONSTRAINT [DF_MI_CustomerActivationPeriod_Archive_ArchiveDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_MI_CustomerActivationPeriod_Archive] PRIMARY KEY CLUSTERED ([ID] ASC)
);

