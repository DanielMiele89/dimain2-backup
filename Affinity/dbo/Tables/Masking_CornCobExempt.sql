CREATE TABLE [dbo].[Masking_CornCobExempt] (
    [Word]      VARCHAR (200) NULL,
    [isBespoke] INT           NOT NULL,
    [id]        INT           IDENTITY (1, 1) NOT NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [CIX_Processing_Masking_CornCob]
    ON [dbo].[Masking_CornCobExempt]([Word] ASC, [isBespoke] ASC);

