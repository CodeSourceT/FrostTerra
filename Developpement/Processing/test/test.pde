FTWindows win;
FTImage img;
FT3DObject obj;
FTGui gui;
FTEvent event;
Dial d;

void settings()
{
  win = new FTWindows("test 2",new FTRect(0,0,640,480),FTRender.N_3D_CONTEXT);
}

void setup()
{
event = new FTEvent(FTEvent.FUNCTION_REGISTER);
setEventManager(event);
gui = new FTGui();
gui.addWidget(new FTLabel("Test", new FTRect(300,10)));
FTButton b = new FTButton("Test", new FTRect(150,200,50,25));
b.setOnClickListener(new A());
gui.addWidget(b);
win.attachDrawClass(new FTRender(FTRender.N_3D_CONTEXT));
FTRender r = (FTRender)win.getDrawClass();
float fov = PI/3.0;
float near = 10.0;
float far = 10.0;

r.attachCamera(new FTCamera(win.getSize(),fov,near,far,FTRender.N_3D_CONTEXT));
r.fillMode(FTRender.NO_FILL);

img = new FTImage("test.jpg", new FTRect(100,200,50), new FTIQuaternion(20,0,0));
//obj = new FT3DObject("Low_Poly_Forest_tree01.obj", new FTRect(300,300,0), new FTIQuaternion(90,0,0));
//obj.setSize(20);
d = new Dial();
}

void draw()
{
 FTRender r = (FTRender)win.getDrawClass();
 r.beginDraw(FTRender.CLEAR_MODE_COLOR,new FTColor(255,255,255));
 fdraw(r);
 r.endDraw();
}

class A implements FTOnClickListener
{
  public A()
  {
  }
  
  @Override
  public void onClick(int id)
  {
    println("Coucou !");
    d.click();
  }
}

class Dial extends FTDialog implements FTDialogButtonClick
{
  FTDialogLabel p;
  FTDialogButton bt;
  FTDialogEditText edt;
  public Dial()
  {
    super("Title",new FTRect(200,200,640,480));
    p=new FTDialogLabel("tom",new FTRect(320,240));
    bt=new FTDialogButton("tom",new FTRect(0,0));
    edt=new FTDialogEditText(new FTRect(10,240,10,0));
    bt.setButtonListener(this);
    this.lockDrawPanel();
    this.addObject(p);
    this.addObject(bt);
    this.addObject(edt);
    this.unlockDrawPanel();
  }
  
  public void click()
  {
    p.setText("tom2");
  }
  
  public void onClick(){
    //p.setText(edt.getText());
    FTDialogBox.getPathSaveFile();
  }
}


void fdraw(FTRender draw)
{
 noFill();
 stroke(1);
/*FTRect r = new FTRect(500,200,0,45,45,45);
draw.r_translate(r.x, r.y, r.z);

draw.draw_box(r);
draw.r_translate(-r.x, -r.y, -r.z);*/

//draw.draw_image(img);
//draw.draw_3Dobject(obj);
//draw.r_translate(50,50,0);
gui.event_gui(event);
gui.draw_gui(draw);
FTEventMotion m = event.searchEvent();
}

/*void keyPressed()
{
  FTRender r = (FTRender)win.getDrawClass();
  r.getCamera().addMove(new FTMove(0,0,0,new FTIQuaternion(0,0.2,0)));
}*/

void playSound()
{
    String filePath="F:\\Programme_Informatique_Perso\\Depot_Developpement\\FrostTerra\\Processing\\test\\data\\whatdo.wav";
    FTAudioSample audio = new FTAudioSample(filePath);
    audio.play();
}
