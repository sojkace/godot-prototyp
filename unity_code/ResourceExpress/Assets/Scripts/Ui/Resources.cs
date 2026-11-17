using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class Resources : MonoBehaviour
{
    [Header("Settings")]
    public string type;
    public Sprite spriteOfResource;
    [Header("UI Elements")]
    [SerializeField]
    private Image imageOfResource;

    [Header("Dont Touch")]
    public bool enough;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetUp()
    {
        imageOfResource.sprite = spriteOfResource;
    }

    public void SetUIEnought(bool b)
    {
        enough = b;
        if (b)
        {
            imageOfResource.color = new Color(1,1,1,1);
        }
        else
        {
            imageOfResource.color = new Color(1, 1, 1, 0.5f);
        }
    }

    public void UpdateUI()
    {
        imageOfResource.sprite = spriteOfResource;
        int currentAmmountOfItem = ItemMaster.instance.GetAmountOfItemsOfType(this);
        if(currentAmmountOfItem > 0)
        {
            SetUIEnought(true);
        }
        else
        {
            SetUIEnought(false);
        }
    }
}
