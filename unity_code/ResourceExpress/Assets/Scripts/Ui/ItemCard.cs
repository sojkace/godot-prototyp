using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ItemCard : MonoBehaviour
{
    public string type;
    public Sprite texture;

    [Header("Holder")]
    [SerializeField]
    private Image image;

    [Header("Dont touch")]
    public ItemCard prefabeOfCard;
    public string currentPosition;
    public bool clicked = false;
    private Transform cardParent;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetUp(ItemCard newPrefabOfCard, string position)
    {
        prefabeOfCard = newPrefabOfCard;
        image.sprite = texture;
        currentPosition = position;
    }

    public void CardClicked()
    {
        if (currentPosition == "Deck")
        {
            ItemMaster.instance.AddItem(type);
            Destroy(gameObject);
        }
        else if (currentPosition == "Marketplace" && clicked)
        {
            SetInSwitchMode(false);
        }
        else if (currentPosition == "Marketplace" && !clicked)
        {
            SetInSwitchMode(true);
        }
    }

    public void SetInSwitchMode(bool inSwitchMode)
    {
        if (inSwitchMode && UiMaster.instance.aktivCardInMP.childCount == 0)
        {
            clicked = true;
            cardParent = transform.parent;
            ItemMaster.instance.itemsWantToSwitch.Add(this);
            GameMaster.instance.phase = "switch";
            transform.SetParent(UiMaster.instance.aktivCardInMP);
            GetComponent<RectTransform>().anchorMax = Vector2.one;
            GetComponent<RectTransform>().anchorMin = Vector2.zero;
            GetComponent<RectTransform>().pivot = new Vector2(0.5f, 0.5f);
            GetComponent<RectTransform>().offsetMax = Vector2.one;
            GetComponent<RectTransform>().offsetMin = Vector2.zero;
        }
        else if (clicked)
        {
            clicked = false;
            ItemMaster.instance.itemsWantToSwitch.Clear();
            GameMaster.instance.phase = "openMP";

            transform.SetParent(cardParent);
            GetComponent<RectTransform>().anchorMax = Vector2.one;
            GetComponent<RectTransform>().anchorMin = Vector2.zero;
            GetComponent<RectTransform>().pivot = new Vector2(0.5f, 0.5f);
            GetComponent<RectTransform>().offsetMax = Vector2.one;
            GetComponent<RectTransform>().offsetMin = Vector2.zero; 
        }
        
    }
}
