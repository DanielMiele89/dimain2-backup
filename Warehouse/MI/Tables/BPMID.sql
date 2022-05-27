CREATE TABLE [MI].[BPMID] (
    [OutletID]  INT          NOT NULL,
    [MID]       VARCHAR (50) NOT NULL,
    [StatusID]  TINYINT      NOT NULL,
    [StartDate] DATE         NOT NULL,
    [EndDate]   DATE         NULL,
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    CONSTRAINT [PK_MI_BPMID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

