CREATE TABLE [dbo].[DeactivatedBand_OLD] (
    [DeactivatedBandID]  SMALLINT     NOT NULL,
    [DeactivatedBand]    VARCHAR (50) NULL,
    [DeactivatedBandMin] INT          NULL,
    [DeactivatedBandMax] INT          NULL,
    CONSTRAINT [PK_DeactivatedBand_OLD] PRIMARY KEY CLUSTERED ([DeactivatedBandID] ASC)
);

