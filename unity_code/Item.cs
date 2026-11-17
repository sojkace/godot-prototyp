using TMPro;
using UnityEngine;
using UnityEngine.UI;


public class Item : MonoBehaviour
{
    [Header("Settings")]
    public string type;
    public Sprite image;
    public int number;
    [Header("UI Elements")]
    [SerializeField]
    private Image imageElment;
    [SerializeField]
    private TMP_Text text;
    [Header("Dont Touch")]
    public string currentPos;
    // Start is called before the first frame update
    void Start()
    {
        SetAktiv(false);
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetUp(int num, string pos)
    {
        currentPos = pos;
        imageElment.sprite = image;
        number = num;
        text.text = num.ToString();
    }

    public void AddItemOfThisType(int num)
    {
        number += num;
        text.text = number.ToString();
    }

    public void RemoveItemOfThisType(int num)
    {
        number -= num;
        text.text = number.ToString();
    }

    public void ItemClicked()
    {
        if(GameMaster.instance.phase == "switch" && !ItemMaster.instance.aktivMarketplace.MarketplaceUsedThisRound)
        {
            ItemMaster.instance.SwitchItemsFromMP(ItemMaster.instance.itemsWantToSwitch[0], this);
        }
    }

    //public void ItemClickedForSwitch()
    //{
    //    if(GameMaster.instance.phase == "switch")
    //    {
    //        SetAktiv(true);
    //        if (UiMaster.instance.itemsWantToSwitch.Count == 1)
    //        {
    //            UiMaster.instance.itemsWantToSwitch.Add(this);

    //            foreach (Item i in ItemMaster.instance.itemsPrefab)
    //            {
    //                if (i.type == UiMaster.instance.itemsWantToSwitch[0].type && UiMaster.instance.itemsWantToSwitch[0].currentPos != UiMaster.instance.itemsWantToSwitch[1].currentPos)
    //                {
    //                    UiMaster.instance.aktivMarketplace.MarketplaceUsedThisRound = false;
    //                    if (UiMaster.instance.itemsWantToSwitch[0].currentPos == "Marketplace")
    //                    {
    //                        ItemMaster.instance.AddItem(UiMaster.instance.itemsWantToSwitch[0].type);
    //                        ItemMaster.instance.RemoveItemFromMarketplacer(UiMaster.instance.itemsWantToSwitch[0].type, 1);

    //                        ItemMaster.instance.AddItemInMarketplace(UiMaster.instance.itemsWantToSwitch[1].type);
    //                        ItemMaster.instance.RemoveItem(UiMaster.instance.itemsWantToSwitch[1].type, 1);
    //                    }
    //                    if (UiMaster.instance.itemsWantToSwitch[0].currentPos == "Inventory")
    //                    {
    //                        ItemMaster.instance.AddItemInMarketplace(UiMaster.instance.itemsWantToSwitch[0].type);
    //                        ItemMaster.instance.RemoveItem(UiMaster.instance.itemsWantToSwitch[0].type, 1);

    //                        ItemMaster.instance.AddItem(UiMaster.instance.itemsWantToSwitch[1].type);
    //                        ItemMaster.instance.RemoveItemFromMarketplacer(UiMaster.instance.itemsWantToSwitch[1].type, 1);
    //                    }
    //                }
    //            }
    //            UiMaster.instance.itemsWantToSwitch[0].SetAktiv(false);
    //            UiMaster.instance.itemsWantToSwitch[1].SetAktiv(false);
    //            UiMaster.instance.itemsWantToSwitch.Clear();

    //        }
    //        else
    //        {
    //            UiMaster.instance.itemsWantToSwitch.Add(this);
    //        }
    //    }

    //}

    public void SetAktiv(bool state)
    {
        if(state)
        {
            GetComponent<Image>().color = Color.green;
        }
        else
        {
            GetComponent<Image>().color = Color.white;
        }
    }

}
