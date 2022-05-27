CREATE TABLE [Relational].[DonationsStatus_PfL] (
    [DonationsStatus_PfL_ID] INT           NOT NULL,
    [Description]            VARCHAR (128) NULL,
    PRIMARY KEY CLUSTERED ([DonationsStatus_PfL_ID] ASC),
    UNIQUE NONCLUSTERED ([DonationsStatus_PfL_ID] ASC)
);

