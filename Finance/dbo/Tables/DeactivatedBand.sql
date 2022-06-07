CREATE TABLE [dbo].[DeactivatedBand] (
    [DeactivatedBandID]  SMALLINT     NOT NULL,
    [DeactivatedBand]    VARCHAR (50) NULL,
    [DeactivatedBandMin] INT          NULL,
    [DeactivatedBandMax] INT          NULL,
    CONSTRAINT [PK_DeactivatedBand] PRIMARY KEY CLUSTERED ([DeactivatedBandID] ASC) WITH (FILLFACTOR = 90)
);

