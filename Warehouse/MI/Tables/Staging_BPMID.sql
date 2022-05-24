CREATE TABLE [MI].[Staging_BPMID] (
    [OutletID] INT          NOT NULL,
    [MID]      VARCHAR (50) NOT NULL,
    [StatusID] TINYINT      NOT NULL,
    CONSTRAINT [PK_MI__Staging_BPMID] PRIMARY KEY CLUSTERED ([OutletID] ASC)
);

