using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

public class Card : MonoBehaviour
{
    [Header("Settings")]
    [SerializeField]
    public Building buildingToBuild;
    [SerializeField]
    private string nameOfCard;
    [SerializeField]
    private string infomations;
    [SerializeField]
    public string deck;

    [Header("UIElements")]
    [SerializeField]
    public RawImage image;
    [SerializeField]
    private TMP_Text infoText;
    [SerializeField]
    private TMP_Text nameText;
    [SerializeField]
    private Image stateImage;
    
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void CardClicked()
    {
        CardMaster.instance.CardClicked(this);
    }

    public void SetUp()
    {
        //infoText.text = infomations;
        nameText.text = nameOfCard;
    }

    public void SetCardState(bool state)
    {
        if (state)
        {
            stateImage.color = new Color(1, 1, 1, 0);
        }
        else
        {
            stateImage.color = new Color(1, 1, 1, 0.5f);
        }
    }
}
