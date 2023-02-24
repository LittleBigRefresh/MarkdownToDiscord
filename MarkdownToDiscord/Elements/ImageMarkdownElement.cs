namespace MarkdownToDiscord.Elements;

public class ImageMarkdownElement : IMarkdownElement
{
    public readonly string Link;
    public readonly string AltText;

    public ImageMarkdownElement(string link, string altText)
    {
        this.Link = link;
        this.AltText = altText;
    }
}