namespace MarkdownToDiscord;

[Serializable]
public class MarkdownSettings
{
    public ulong ChannelId { get; set; }
    public bool ShouldDeleteExistingContents { get; set; } = true;
    public string Title { get; set; } = ""; // workaround for writerside
}
