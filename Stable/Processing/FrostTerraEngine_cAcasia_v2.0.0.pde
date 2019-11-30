import javax.sound.sampled.AudioInputStream; 
import javax.sound.sampled.AudioSystem; 
import javax.sound.sampled.Clip; 
import javax.sound.sampled.LineUnavailableException; 
import javax.sound.sampled.UnsupportedAudioFileException;
import javax.swing.JOptionPane;
import javax.swing.JFileChooser;
import javax.swing.JDialog;
import javax.swing.JPanel;
import java.awt.Component;
import java.awt.Container;
import javax.swing.JLabel;
import javax.swing.JButton;
import javax.swing.JTextField;
import java.awt.Dimension;
import java.awt.Insets;
import java.awt.event.*;
import java.io.*;
import java.util.Random;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.awt.MouseInfo;
import java.awt.Point;
import java.awt.Robot;
import java.awt.GraphicsEnvironment;
import java.awt.AWTException;
import javax.swing.KeyStroke;
import com.jogamp.newt.opengl.GLWindow;

abstract class FTObject
{
  private String name = "null";
  
  public FTObject(String n)
  {
    name = n;
  }
  
  public String getName()
  {
    return name;
  }
}

class FTWindows extends FTObject
{
  private FTRect m_sw;
  private String m_fmr;
  private FTRenderInterface m_render;
  private GLWindow canvas;
  
  public FTWindows(String name_w, FTRect size_win, String flags_mode_render)
  {
    super("FTWINDOWS " + name_w);
    m_sw = size_win;
    m_fmr = flags_mode_render;
    if(flags_mode_render == FTRender.N_2D_CONTEXT)
    {
      size(size_win.w,size_win.h);
    }
    else
    {
      size(size_win.w,size_win.h,flags_mode_render);
    }
  }
  
  public void setTitle(String t)
  {
    canvas = _getFrame();
    canvas.setTitle(t);
  }
  
  public FTRect getSize()
  {
    return m_sw;
  }
  
  public String getFlagMode()
  {
    return m_fmr;
  }
  
  public void attachDrawClass(FTRenderInterface render_class)
  {
    m_render = render_class;
  }
  
  public FTRenderInterface getDrawClass()
  {
    return m_render;
  }
  
  public FTRect getPosition()
  {
    return new FTRect(canvas.getX(),canvas.getY());
  }
  
  private GLWindow _getFrame() {
  PSurfaceJOGL surf = (PSurfaceJOGL) getSurface();
  if(surf == null)
  {
    return null;
  }
  GLWindow canvas = (GLWindow) surf.getNative();
  return canvas;
  }

}

abstract class FTDialog extends JDialog
{
  private JPanel panel = new JPanel();
  private boolean lock_surface = false;
  
  public FTDialog(String title, FTRect pew)
  {
    this(title,pew,false);
  }
  
  public FTDialog(String title, FTRect pew, boolean resizable)
  {
    this(title,pew,resizable,true);
  }
  
  public FTDialog(String title, FTRect pew, boolean resizable, boolean visible)
  {
    this.setTitle(title);
    this.setLocation(pew.x,pew.y);
    this.setSize(pew.w,pew.h);
    this.setResizable(resizable);
    
    panel.setLayout(null);
    Container contentPane = getContentPane();
    contentPane.add(panel);
    this.setVisible(visible);
  }
  
  public void lockDrawPanel()
  {
    if(!lock_surface)
    {
    this.setVisible(false);
    lock_surface=true;
    }
  }
  
  public void unlockDrawPanel()
  {
    if(lock_surface)
    {
    this.setVisible(true);
    lock_surface=false;
    }
  }
  
  public void addObject(FTDialogObject obj)
  {
    Component c = obj.getComponent();
    Dimension d = c.getPreferredSize();
    //Insets insets = panel.getInsets();
    FTRect pos = obj.getPosition();
   // pos.x = pos.x + insets.left;
    //pos.y = pos.y + insets.top;
    c.setBounds(pos.x,pos.y,d.width,d.height);
    lockDrawPanel();
    panel.add(c);
    unlockDrawPanel();
  }
}

abstract class FTDialogObject extends FTObject
{
  private Component m_object;
  private FTRect pos;
  
  public FTDialogObject(FTRect p)
  {
    super("FTDialogObject");
    pos=p;
  }
  
  public void setComponent(Component c)
  {
    m_object = c;
  }
  
  public Component getComponent()
  {
    return m_object;
  }
  
  public void setPosition(FTRect p)
  {
    pos=p;
  }
  
  public FTRect getPosition()
  {
    return pos;
  }
}

class FTDialogLabel extends FTDialogObject
{
  public FTDialogLabel(String label, FTRect pos)
  {
    super(pos);
    this.setComponent(new JLabel(label));
  }
  
  public String getText()
  {
    JLabel l = (JLabel)this.getComponent();
    return l.getText();
  }
  
  public void setText(String t)
  {
    JLabel l = (JLabel)this.getComponent();
    l.setText(t);
    Dimension d = l.getPreferredSize();
    FTRect pos = this.getPosition();
    l.setBounds(pos.x,pos.y,d.width,d.height);
    this.setComponent(l);
  }
}

interface FTDialogButtonClick
{
  public void onClick();
}

class FTDialogButton extends FTDialogObject implements ActionListener
{
  private FTDialogButtonClick m_callable=null;
  
  public FTDialogButton(String txt, FTRect pos)
  {
    super(pos);
    JButton b = new JButton(txt);
    b.addActionListener(this);
    this.setComponent(b);
  }
  
  public void setButtonListener(FTDialogButtonClick c)
  {
    m_callable=c;
  }
  
  public String getText()
  {
    JButton l = (JButton)this.getComponent();
    return l.getText();
  }
  
  public void setText(String t)
  {
    JButton l = (JButton)this.getComponent();
    l.setText(t);
    Dimension d = l.getPreferredSize();
    FTRect pos = this.getPosition();
    l.setBounds(pos.x,pos.y,d.width,d.height);
    this.setComponent(l);
  }
  
  @Override
  public void actionPerformed(ActionEvent e) {
    if(m_callable != null)
    {
      m_callable.onClick();
    }
  }
}

class FTDialogEditText extends FTDialogObject
{
  private boolean is_edit = true;
  public FTDialogEditText(FTRect pos)
  {
    this("",pos);
  }
  
  public FTDialogEditText(String pre_text, FTRect pos)
  {
    this(pre_text,pos,true);
  }
  
  public FTDialogEditText(String pre_text, FTRect pos, boolean edit)
  {
    super(pos);
    JTextField t = new JTextField(pre_text,pos.w);
    t.setEditable(edit);
    this.setComponent(t);
    is_edit=edit;
    this.setComponent(t);
  }
  
  public void setEdit(boolean edit)
  {
    is_edit=edit;
    JTextField t = (JTextField)this.getComponent();
    t.setEditable(edit);
  }
  
  public boolean getEdit()
  {
    return is_edit;
  }
  
  public String getText()
  {
    JTextField t = (JTextField)this.getComponent();
    return t.getText();
  }
}

static class FTDialogBox
{
  public static final int NONE_MESSAGE = 100;
  public static final int INFORMATION_MESSAGE = 101;
  public static final int WARNING_MESSAGE = 102;
  public static final int ERROR_MESSAGE = 103;
  public static final int QUESTION_MESSAGE = 104;
  
  public static void showDialog(String title, String msg)
  {
    FTDialogBox.showDialog(title,msg,INFORMATION_MESSAGE);
  }
  
  public static void showDialog(String title, String msg, int type)
  {
    int fltp = JOptionPane.PLAIN_MESSAGE;
    switch(type)
    {
      case FTDialogBox.NONE_MESSAGE:
      fltp = JOptionPane.PLAIN_MESSAGE;
      break;
      case FTDialogBox.INFORMATION_MESSAGE:
      fltp = JOptionPane.INFORMATION_MESSAGE;
      break;
      case FTDialogBox.WARNING_MESSAGE:
      fltp = JOptionPane.WARNING_MESSAGE;
      break;
      case FTDialogBox.ERROR_MESSAGE:
      fltp = JOptionPane.ERROR_MESSAGE;
      break;
      case FTDialogBox.QUESTION_MESSAGE:
      fltp = JOptionPane.QUESTION_MESSAGE;
      break;
    }
    JOptionPane.showMessageDialog(null,
    msg,
    title,
    fltp);
  }
  
  public static String getPathSaveFile()
  {
    JFileChooser saveFile = new JFileChooser();
                int result = saveFile.showSaveDialog(null);
                if (result == JFileChooser.APPROVE_OPTION) {
                  File selectedFile = saveFile.getSelectedFile();
                  return selectedFile.getAbsolutePath();
                }
    return "";
  }
  
  public static String getPathOpenFile()
  {
    JFileChooser saveFile = new JFileChooser();
                int result = saveFile.showOpenDialog(null);
                if (result == JFileChooser.APPROVE_OPTION) {
    File selectedFile = saveFile.getSelectedFile();
       return selectedFile.getAbsolutePath();
            }
     return "";
  }
}

interface FTOnClickListener
{
  public void onClick(int id);
}

interface FTOnMouseListener
{
  public void onMouseClick(FTMouseMotion mouse);
  public void onMousePressed(FTMouseMotion mouse);
  public void onMouseReleased(FTMouseMotion mouse);
  public void onMouseDragged(FTMouseMotion mouse);
  public void onMouseMoved(FTMouseMotion mouse);
}

interface FTOnKeyBoardListener
{
  public void onKeyPressed(FTKeyboardMotion keyboard);
  public void onKeyReleased(FTKeyboardMotion keyboard);
}

private FTEvent m_frostterra_event_manager;
private boolean is_event_manager_set = false;
private long millis_time_event_move = 0;

void setEventManager(FTEvent ev)
{
  m_frostterra_event_manager = ev;
  is_event_manager_set = true;
  millis_time_event_move=millis();
}

class FTEvent extends FTObject
{
  private FTOnMouseListener m_mouse_listener;
  private FTOnKeyBoardListener m_keyboard_listener;
  private boolean is_m_l;
  private boolean is_k_l;
  private int mode_register;
  private ArrayList<FTEventMotion> m_queue_events;
  
  public static final int INTERFACE_REGISTER = 95;
  public static final int FUNCTION_REGISTER = 96;
  public static final int NONE_EVENT = 97;
  public static final int MOUSE_EVENT = 98;
  public static final int KEYBOARD_EVENT = 99;
  public static final int KEYBOARD_PRESSED = 100;
  public static final int KEYBOARD_RELEASED = 101;
  public static final int MOUSE_PRESSED = 102;
  public static final int MOUSE_RELEASED = 103;
  public static final int MOUSE_CLICKED = 104;
  public static final int MOUSE_DRAGGED = 105;
  public static final int MOUSE_MOVED = 106;
  
  public FTEvent()
  {
    this(INTERFACE_REGISTER);
  }
  
  public FTEvent(int mr)
  {
    super("FTEvent : " + mr);
    m_mouse_listener=null;
    m_keyboard_listener=null;
    is_m_l=false;
    is_k_l=false;
    m_queue_events = new ArrayList<FTEventMotion>();
    mode_register=mr;
  }
  
  public int getMethodRegister()
  {
    return mode_register;
  }
  
  public void setMouseListerner(FTOnMouseListener a)
  {
    m_mouse_listener = a;
  }
  
  public void setKeyboardListener(FTOnKeyBoardListener a)
  {
    m_keyboard_listener =a ;
  }
  
  public void add_event(FTMotion event)
  {
    switch(event.getTypeEvent())
    {
      case MOUSE_EVENT:
      _dispatch_mouse_event((FTMouseMotion)event);
      break;
      case KEYBOARD_EVENT:
      _dispatch_keyboard_event((FTKeyboardMotion)event);
      break;
    }
  }
  
  public FTEventMotion searchEvent()
  {
    return _popEvent();
  }
  
  private void _dispatch_mouse_event(FTMouseMotion m)
  {
    if(mode_register == INTERFACE_REGISTER && is_m_l)
    {
    switch(m.mouse_event_type)
    {
      case MOUSE_CLICKED:
      m_mouse_listener.onMouseClick(m);
      break;
      case MOUSE_PRESSED:
      m_mouse_listener.onMousePressed(m);
      break;
      case MOUSE_RELEASED:
      m_mouse_listener.onMouseReleased(m);
      break;
      case MOUSE_MOVED:
      m_mouse_listener.onMouseMoved(m);
      break;
      case MOUSE_DRAGGED:
      m_mouse_listener.onMouseDragged(m);
      break;
    }
    }
    else if(mode_register == FUNCTION_REGISTER)
    {
      _pushEvent(m, MOUSE_EVENT);
    }
  }
  
  private void _dispatch_keyboard_event(FTKeyboardMotion m)
  {
    if(mode_register == INTERFACE_REGISTER && is_k_l)
    {
    switch(m.key_code_event)
    {
      case KEYBOARD_PRESSED:
      m_keyboard_listener.onKeyPressed(m);
      break;
      case KEYBOARD_RELEASED:
      m_keyboard_listener.onKeyReleased(m);
      break;
    }
    }
    else if(mode_register == FUNCTION_REGISTER)
    {
      _pushEvent(m, KEYBOARD_EVENT);
    }
  }
  
  private void _pushEvent(FTMotion event, int te)
  {
    m_queue_events.add(new FTEventMotion(event,te));
  }
  
  private FTEventMotion _popEvent()
  {
    FTEventMotion event = null;
    if(m_queue_events.size() > 0)
    {
      event = m_queue_events.get(0);
      m_queue_events.remove(0);
    }
    else
    {
      event = new FTEventMotion(null, NONE_EVENT);
    }
    
    return event;
  }
}

interface FTMotion
{
  public int getTypeEvent();
}

class FTEventMotion extends FTObject
{
  private FTMotion m_event;
  private int type_event;
  
  public FTEventMotion(FTMotion e, int te)
  {
    super("FTEventMotion : FTMotion " + te);
    m_event = e;
    type_event = te;
  }
  
  public int getTypeEvent()
  {
    return type_event;
  }
  
  public FTMotion getEvent()
  {
    return m_event;
  }
  
  public FTMouseMotion getTypedEventMouse()
  {
    FTMouseMotion e=null;
    if(type_event == FTEvent.MOUSE_EVENT)
    {
      e = (FTMouseMotion)m_event;
    }
    
    return e;
  }
  
  public FTKeyboardMotion getTypedEventKeyboard()
  {
    FTKeyboardMotion e=null;
    if(type_event == FTEvent.KEYBOARD_EVENT)
    {
      e = (FTKeyboardMotion)m_event;
    }
    
    return e;
  }
}

class FTMouseMotion extends FTObject implements FTMotion
{
  private int mouse_event_type;
  private int mouse_x, mouse_y;
  private int mouse_button;
  
  public static final int BUTTON_LEFT = 200;
  public static final int BUTTON_RIGHT = 201;
  
  public FTMouseMotion()
  {
    super("FTMouseMotion : none");
    mouse_x=0;
    mouse_y=0;
  }
  
  public FTMouseMotion(int a, int b, int c, int d)
  {
    super("FTMouseMotion :" +a + " " + b + " " +c + " " + d);
    mouse_event_type=a;
    mouse_x=b;
    mouse_y=c;
    if(d==LEFT)
    {
      mouse_button=BUTTON_LEFT;
    }
    else
    {
      mouse_button=BUTTON_RIGHT;
    }
  }
  
  public int getMouseX()
  {
    return mouse_x;
  }
  
  public int getMouseY()
  {
    return mouse_y;
  }
  
  public int getTypeEvent()
  {
    return FTEvent.MOUSE_EVENT;
  }
  
  public int getTypeMouseEvent()
  {
    return mouse_event_type;
  }
  
  public int getTypeButton()
  {
    return mouse_button;
  }
}

class FTKeyboardMotion extends FTObject implements FTMotion
{
  private int key_code_event;
  private int key_code;
    
  public FTKeyboardMotion()
  {
    super("FTKeyboardMotion : none");
    key_code=0;
  }
  
  public FTKeyboardMotion(int a, int b)
  {
    super("FTKeyboardMotion :" + a + " " + b);
    key_code_event=a;
    key_code=b;
  }
  
  public int getKeycode()
  {
    return key_code;
  }
  
  public int getTypeEvent()
  {
    return FTEvent.KEYBOARD_EVENT;
  }
  
  public int getTypeKeyboardEvent()
  {
    return key_code_event;
  }
}

class FTRobot extends FTObject
{
  private Robot m_robot;
  
  public FTRobot()
  {
    super("FTMouseRobot");
    try
    {
    m_robot = new Robot();
    }
    catch(AWTException e)
    {
    }
  }
  
  public void sim_event_mouse(FTMouseMotion me)
  {
    switch(me.getTypeMouseEvent())
    {
      case FTEvent.MOUSE_PRESSED:
      switch(me.getTypeButton())
      {
        case FTMouseMotion.BUTTON_LEFT:
        m_robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
        break;
        case FTMouseMotion.BUTTON_RIGHT:
        m_robot.mousePress(InputEvent.BUTTON2_DOWN_MASK);
        break;
      }
      break;
      case FTEvent.MOUSE_RELEASED:
      switch(me.getTypeButton())
      {
        case FTMouseMotion.BUTTON_LEFT:
        m_robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
        break;
        case FTMouseMotion.BUTTON_RIGHT:
        m_robot.mouseRelease(InputEvent.BUTTON2_DOWN_MASK);
        break;
      }
      break;
      case FTEvent.MOUSE_MOVED:
      m_robot.mouseMove(me.getMouseX(),me.getMouseY());
      break;
      case FTEvent.MOUSE_CLICKED:
      switch(me.getTypeButton())
      {
        case FTMouseMotion.BUTTON_LEFT:
        m_robot.mousePress(InputEvent.BUTTON1_DOWN_MASK);
        m_robot.mouseRelease(InputEvent.BUTTON1_DOWN_MASK);
        break;
        case FTMouseMotion.BUTTON_RIGHT:
        m_robot.mousePress(InputEvent.BUTTON2_DOWN_MASK);
        m_robot.mouseRelease(InputEvent.BUTTON2_DOWN_MASK);
        break;
      }
      break;
    }
  }
  
  public void sim_event_keyboard(FTKeyboardMotion ke)
  {
    KeyStroke ks = KeyStroke.getKeyStroke(ke.getKeycode(), 0);
    switch(ke.getTypeKeyboardEvent())
    {
      case FTEvent.KEYBOARD_PRESSED:
      m_robot.keyPress(ks.getKeyCode());
      break;
      case FTEvent.KEYBOARD_RELEASED:
      m_robot.keyRelease(ks.getKeyCode());
      break;
    }
  }
}

void mouseClicked()
{
  if(is_event_manager_set)
  {
    m_frostterra_event_manager.add_event(new FTMouseMotion(FTEvent.MOUSE_CLICKED,mouseX,mouseY,mouseButton));
  }
}

void mousePressed()
{
  if(is_event_manager_set)
  {
    m_frostterra_event_manager.add_event(new FTMouseMotion(FTEvent.MOUSE_PRESSED,mouseX,mouseY,mouseButton));
  }
}

void mouseReleased()
{
  if(is_event_manager_set)
  {
    m_frostterra_event_manager.add_event(new FTMouseMotion(FTEvent.MOUSE_RELEASED,mouseX,mouseY,mouseButton));
  }
}

void mouseMoved()
{
  if(is_event_manager_set)
  {
    if((millis()-millis_time_event_move)>500)
    {
      millis_time_event_move=millis();
      m_frostterra_event_manager.add_event(new FTMouseMotion(FTEvent.MOUSE_MOVED,mouseX,mouseY,mouseButton));
    }
  }
}

void mouseDragged()
{
  if(is_event_manager_set)
  {
    m_frostterra_event_manager.add_event(new FTMouseMotion(FTEvent.MOUSE_DRAGGED,mouseX,mouseY,mouseButton));
  }
}

void keyPressed()
{
  if(is_event_manager_set)
  {
    m_frostterra_event_manager.add_event(new FTKeyboardMotion(FTEvent.KEYBOARD_PRESSED,key));
  }
}

void keyReleased()
{
  if(is_event_manager_set)
  {
    m_frostterra_event_manager.add_event(new FTKeyboardMotion(FTEvent.KEYBOARD_RELEASED,key));
  }
}

interface FTRenderInterface
{
  public void beginDraw(int clear_mode);
  public void beginDraw(int clear_mode, FTColor col);
  public void endDraw();
  public void free();
}

class FTRender extends FTObject implements FTRenderInterface
{
  public static final String N_2D_CONTEXT = "2d_context";
  public static final String N_3D_CONTEXT = P3D;
  public static final int CLEAR_MODE_NORMAL = 100;
  public static final int CLEAR_MODE_BLACK = 101;
  public static final int CLEAR_MODE_WHITE = 102;
  public static final int CLEAR_MODE_COLOR = 103;
  public static final int NO_FILL = 104;
  public static final int FILL_COLOR = 105;
  public static final int NO_STROKE = 106;
  public static final int STROKE_COLOR = 107;
  
  private String m_mode;
  private FTCamera m_cam;
  
  public FTRender(String mode)
  {
    super("FTRender : "+ mode);
    m_mode = mode;
  }
  
  public void beginDraw(int clear_mode)
  {
     switch(clear_mode)
     {
       case CLEAR_MODE_NORMAL:
       beginDraw(CLEAR_MODE_COLOR, new FTColor(FTColor.WHITE));
       break;
       default:
       beginDraw(clear_mode, null);
       break;
     }
  }
  
  public void beginDraw(int clear_mode, FTColor col)
  {
    switch(clear_mode)
     {
       case CLEAR_MODE_NORMAL:
       beginDraw(CLEAR_MODE_COLOR, new FTColor(FTColor.WHITE));
       break;
       case CLEAR_MODE_WHITE:
       beginDraw(CLEAR_MODE_COLOR, new FTColor(FTColor.WHITE));
       break;
       case CLEAR_MODE_BLACK:
       beginDraw(CLEAR_MODE_COLOR, new FTColor(FTColor.BLACK));
       break;
       case CLEAR_MODE_COLOR:
       clear();
       background(col.red(),col.green(),col.blue());
       break;
     }
  }
  
  public void endDraw()
  {
  }
  
  public void free()
  {
  }
  
  public void attachCamera(FTCamera c)
  {
    m_cam = c;
  }
  
  public FTCamera getCamera()
  {
    return m_cam;
  }
  
  public void r_translate(int x, int y)
  {
    translate(x,y);
  }
  
  public void r_translate(int x, int y, int z)
  {
    translate(x,y,z);
  }
  
  public void r_rotate(float a)
  {
    rotate(a);
  }
  
  public void r_rotate(float x, float y, float z)
  {
    rotateX(x);
    rotateY(y);
    rotateZ(z);
  }
  
  public void fillMode(int m)
  {
    switch(m)
    {
      case NO_FILL:
      noFill();
      break;
      case FILL_COLOR:
      fillMode(new FTColor(FTColor.BLACK));
      break;
    }
  }
  
  public void fillMode(FTColor c)
  {
    fill(c.red(),c.green(),c.blue());
  }
  
  public void strokeMode(int m)
  {
    switch(m)
    {
      case NO_STROKE:
      noStroke();
      break;
      case STROKE_COLOR:
      strokeMode(new FTColor(FTColor.BLACK));
      break;
    }
  }
  
  public void strokeMode(FTColor c)
  {
    stroke(c.red(),c.green(),c.blue());
  }
  
  public void draw_point(FTRect object)
  {
    point(object.x,object.y,object.z);
  }
  
  public void draw_line(FTRect object)
  {
    line(object.x,object.y,object.z,(object.x+object.w),(object.y+object.h),(object.z+object.p));
  }
  
  public void draw_box(FTRect object)
  {
    if(m_mode == N_2D_CONTEXT)
    {
      rect(object.x,object.y,object.w,object.h);
    }
    else
    {
      box(object.w,object.h,object.p);
    }
  }
  
  public void draw_triangle(FTRect obj1, FTRect obj2, FTRect obj3)
  {
    triangle(obj1.x,obj1.y,obj2.x,obj2.y,obj3.x,obj3.y);
  }
  
  public void draw_image(FTImage s)
  {
    translate(s.getPositionAndSize().x,s.getPositionAndSize().y,s.getPositionAndSize().z);
    if(m_mode == N_2D_CONTEXT)
    {
      rotate(s.getRotation().qx);
    }
    else
    {
      rotateX(s.getRotation().qx);
      rotateY(s.getRotation().qy);
      rotateZ(s.getRotation().qz);
    }
    
    s.draw_surface(FTImage.DRAW_REL);
    
    
    
    if(m_mode == N_2D_CONTEXT)
    {
      rotate(-s.getRotation().qx);
    }
    else
    {
      rotateX(-s.getRotation().qx);
      rotateY(-s.getRotation().qy);
      rotateZ(-s.getRotation().qz);
    }
    
    translate(-s.getPositionAndSize().x,-s.getPositionAndSize().y,-s.getPositionAndSize().z);
  }
  
  public void draw_3Dobject(FT3DObject s)
  {
    translate(s.getPosition().x,s.getPosition().y,s.getPosition().z);
    if(m_mode == N_2D_CONTEXT)
    {
      rotate(s.getRotation().qx);
    }
    else
    {
      rotateX(s.getRotation().qx);
      rotateY(s.getRotation().qy);
      rotateZ(s.getRotation().qz);
    }
    
    s.draw_object(FT3DObject.DRAW_REL);
    
   
    
    if(m_mode == N_2D_CONTEXT)
    {
      rotate(-s.getRotation().qx);
    }
    else
    {
      rotateX(-s.getRotation().qx);
      rotateY(-s.getRotation().qy);
      rotateZ(-s.getRotation().qz);
    }
    
     translate(-s.getPosition().x,-s.getPosition().y,-s.getPosition().z);
  }
  
  public void draw_text(FTText text)
  {
    translate(text.getPosition().x,text.getPosition().y,text.getPosition().z);
    if(m_mode == N_2D_CONTEXT)
    {
      rotate(text.getRotation().qx);
    }
    else
    {
      rotateX(text.getRotation().qx);
      rotateY(text.getRotation().qy);
      rotateZ(text.getRotation().qz);
    }
    
    text.draw_object(FTText.DRAW_REL);
    
    if(m_mode == N_2D_CONTEXT)
    {
      rotate(-text.getRotation().qx);
    }
    else
    {
      rotateX(-text.getRotation().qx);
      rotateY(-text.getRotation().qy);
      rotateZ(-text.getRotation().qz);
    }
    
     translate(-text.getPosition().x,-text.getPosition().y,-text.getPosition().z);
  }
}

abstract class FTCamera extends FTObject
{
  public FTRect m_forward;
  public FTRect m_position;
  public FTRect m_view;
  public FTIQuaternion m_rotation;
  public String m_mode_projection;
  
  public FTCamera(String name, FTRect sw, float focale, float near, float far, String mode_r)
  {
    super(name);
    m_position = new FTRect();
    m_view = new FTRect();
    m_rotation = new FTIQuaternion();
    m_mode_projection = mode_r;
    m_forward = new FTRect((int)(width/2.0),(int)(height/2.0),0);
    
    if(mode_r == FTRender.N_2D_CONTEXT)
    {
      ortho(-sw.w/2, sw.w/2, -sw.h/2, sw.h/2);
    }
    else
    {
      float fov = focale;
      float cameraZ = (sw.h/2.0) / tan(fov/2.0);
      perspective(fov, float(sw.w)/float(sw.h), 
            cameraZ/near, cameraZ*far);
    }
  }
  
  public void initData(FTRect pos, FTRect view, FTIQuaternion rot)
  {
    m_position = pos;
    m_view = view;
    m_rotation = rot;
    
    _active_transform_camera();
    
    if(m_mode_projection == FTRender.N_2D_CONTEXT)
    {
      translate(m_position.x,m_position.y);
      rotate(m_rotation.qx);
    }
    else
    {
      translate(m_position.x,m_position.y,m_position.z);
      rotateX(m_rotation.qx);
      rotateY(m_rotation.qy);
      rotateZ(m_rotation.qz);
      //camera(m_position.x,m_position.y,m_position.z,m_forward.x, m_forward.y, m_forward.z, 0, 1, 0);
    }
    
    _flush_transform_camera();
  }
  
  public void addMove(FTMove m, FTRect ford)
  {
    m_forward = ford;
    m_position = m.applyMove(m_position);
    m_rotation = m.applyRotation(m_rotation);
    
   _active_transform_camera();
    
    if(m_mode_projection == FTRender.N_2D_CONTEXT)
    {
      translate(m_position.x,m_position.y);
      rotate(m_rotation.qx);
    }
    else
    {
     translate(m_position.x,m_position.y,m_position.z);
      rotateX(m_rotation.qx);
      rotateY(m_rotation.qy);
      rotateZ(m_rotation.qz);
         //camera(m_position.x,m_position.y,m_position.z,m_forward.x, m_forward.y, m_forward.z, 0, 1, 0);
    }
    
    _flush_transform_camera();
  }
  
  public void addMove(FTMove m)
  {
   addMove(m,m_forward);
  }
  
  private void _active_transform_camera()
  {
    beginCamera();
    camera();
  }
  
  private void _flush_transform_camera()
  {
    endCamera();
  }
}

class FTBasicCamera extends FTCamera
{
  public FTBasicCamera(FTRect sw, float focale, float near, float far, String mode_r)
  {
    super("FTBasicCamera : " + sw.getName() + " " + focale + " " + near + " " + far + " " + mode_r,sw,focale,near,far,mode_r);
  }  
}

class FTFPSCamera extends FTCamera
{
  private FTRobot m_robot;
  private boolean m_touch_right=false;
  private boolean m_touch_left=false;
  private boolean m_touch_up=false;
  private boolean m_touch_down=false;
  private int speed = 2;
  public boolean controllable;
  public float sensitivity;
  public PVector position;
  public float pan;
  public float tilt;
  public PVector velocity;
  public float friction;
  private PVector center;
  private PVector up;
  private PVector right;
  private PVector forward;
  private PVector target;
  private Point mouse;
  private Point prevMouse;
  private FTRect size_win;
  
  public FTFPSCamera(FTRect sw, float focale, float near, float far, String mode_r)
  {
    super("FTFPSCamera : " + sw.getName() + " " + focale + " " + near + " " + far + " " + mode_r,sw,focale,near,far,mode_r);
    m_robot = new FTRobot();
    controllable = true;
    sensitivity = 2f;
    position = new PVector(0f, 0f, 0f);
    up = new PVector(0f, 1f, 0f);
    right = new PVector(1f, 0f, 0f);
    forward = new PVector(0f, 0f, 1f);
    velocity = new PVector(0f, 0f, 0f);
    pan = 0f;
    tilt = 0f;
    friction = 0.75f;
  }
  
  public void setSpeed(int a)
  {
    speed=a;
  }
  
  public int getSpeed()
  {
    return speed;
  }
  
  public void parseEvent(FTWindows win, FTEvent event)
  {
    if(event.getMethodRegister() != FTEvent.FUNCTION_REGISTER)
    {
      return;
    }
    
    FTEventMotion em = event.searchEvent();
    boolean is_repop = true;
    
    size_win=win.getSize();
    
    switch(em.getTypeEvent())
    {
      case FTEvent.NONE_EVENT:
      is_repop = false;
      break;
      case FTEvent.MOUSE_EVENT:
      case FTEvent.KEYBOARD_EVENT:
      _internal_dispatch_event(em);
      break;
    }
    
     _internal_mouse_event();
    
    if(is_repop)
    {
      event.add_event(em.getEvent());
    }
  }
  
  private void updateCamera()
  {
    
    if(m_touch_right)
    {
     velocity.sub(PVector.mult(right, speed));
    }
    else if(m_touch_left)
    {
    velocity.add(PVector.mult(right, speed));
    }
    else if(m_touch_up)
    {
      velocity.add(PVector.mult(forward, speed));
    }
    else if(m_touch_down)
    {
     velocity.sub(PVector.mult(forward, speed));
    }
  }
  
  private void _internal_dispatch_event(FTEventMotion em)
  {
    switch(em.getTypeEvent())
    {
      case FTEvent.KEYBOARD_EVENT:
      FTKeyboardMotion keyb = (FTKeyboardMotion)em.getTypedEventKeyboard();
      char c = (char)keyb.getKeycode();
       if(c == 'd')
       { 
         switch(keyb.getTypeKeyboardEvent())
          {
            case FTEvent.KEYBOARD_PRESSED:
            m_touch_right=true;
            break;
            case FTEvent.KEYBOARD_RELEASED:
            m_touch_right=false;
            break;
          } 
       }
       else if(c == 'q')
       {
         switch(keyb.getTypeKeyboardEvent())
          {
            case FTEvent.KEYBOARD_PRESSED:
            m_touch_left=true;
            break;
            case FTEvent.KEYBOARD_RELEASED:
            m_touch_left=false;
            break;
          } 
       }
       else if(c == 'z')
       {
         switch(keyb.getTypeKeyboardEvent())
          {
            case FTEvent.KEYBOARD_PRESSED:
            m_touch_up=true;
            break;
            case FTEvent.KEYBOARD_RELEASED:
            m_touch_up=false;
            break;
          } 
       }
       else if(c == 's')
       {
         switch(keyb.getTypeKeyboardEvent())
          {
            case FTEvent.KEYBOARD_PRESSED:
            m_touch_down=true;
            break;
            case FTEvent.KEYBOARD_RELEASED:
            m_touch_down=false;
            break;
          } 
       }
      break;
    }
  }
  
  private void _internal_mouse_event()
  {
    mouse = MouseInfo.getPointerInfo().getLocation();
    if (prevMouse == null) prevMouse = new Point(mouse.x, mouse.y);
    
    int w = GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds().width;
    int h = GraphicsEnvironment.getLocalGraphicsEnvironment().getMaximumWindowBounds().height;
    
    if (mouse.x < 1 && (mouse.x - prevMouse.x) < 0){
       m_robot.sim_event_mouse(new FTMouseMotion(FTEvent.MOUSE_MOVED,w-2, mouse.y,-1));
      mouse.x = w-2;
      prevMouse.x = w-2;
    }
        
    if (mouse.x > w-2 && (mouse.x - prevMouse.x) > 0){
      m_robot.sim_event_mouse(new FTMouseMotion(FTEvent.MOUSE_MOVED,2, mouse.y,-1));
      mouse.x = 2;
      prevMouse.x = 2;
    }
    
    if (mouse.y < 1 && (mouse.y - prevMouse.y) < 0){
      m_robot.sim_event_mouse(new FTMouseMotion(FTEvent.MOUSE_MOVED,mouse.x, h-2,-1));
      mouse.y = h-2;
      prevMouse.y = h-2;
    }
    
    if (mouse.y > h-1 && (mouse.y - prevMouse.y) > 0){
      m_robot.sim_event_mouse(new FTMouseMotion(FTEvent.MOUSE_MOVED,mouse.x, 2,-1));
      mouse.y = 2;
      prevMouse.y = 2;
    }
    
    pan += PApplet.map(mouse.x - prevMouse.x, 0, size_win.w, 0, PConstants.TWO_PI) * sensitivity;
    tilt += PApplet.map(mouse.y - prevMouse.y, 0, size_win.h, 0, PConstants.PI) * sensitivity;
    tilt = clamp(tilt, -PConstants.PI/2.01f, PConstants.PI/2.01f);
    
    if (tilt == PConstants.PI/2) tilt += 0.001f;

    forward = new PVector(PApplet.cos(pan), PApplet.tan(tilt), PApplet.sin(pan));
    forward.normalize();
    right = new PVector(PApplet.cos(pan - PConstants.PI/2), 0, PApplet.sin(pan - PConstants.PI/2));
        
        target = PVector.add(position, forward);
    
    prevMouse = new Point(mouse.x, mouse.y);
    
    updateCamera();
    
    velocity.mult(friction);
    position.add(velocity);
    center = PVector.add(position, forward);
    camera(position.x, position.y, position.z, center.x, center.y, center.z, up.x, up.y, up.z);
  }
  
  private float clamp(float x, float min, float max){
    if (x > max) return max;
    if (x < min) return min;
    return x;
  }
}

class FTImage extends FTObject
{
  private PImage m_surface;
  private FTRect m_pos_size;
  private FTIQuaternion m_rot;
  
  public static final int DRAW_ABS = 200;
  public static final int DRAW_REL = 201;
  
  public FTImage(FTRect size, FTRect pos, int mode)
  {
   super("FTImage : " + size.getName() + " "+ pos.getName() + " " +mode);
    m_surface = createImage(size.w,size.h,mode);
    m_pos_size = new FTRect(pos.x, pos.y, size.w, size.h);
  }
  
  public FTImage(FTRect size, FTRect pos, FTIQuaternion rot, int mode)
  {
    super("FTImage : " + size.getName() + " "+ pos.getName() + " " + rot.getName() + " " +mode);
    m_surface = createImage(size.w,size.h,mode);
    m_pos_size = new FTRect(pos.x, pos.y, size.w, size.h);
    m_rot = rot;
  }
  
  public FTImage(String path, FTRect pos)
  {
    super("FTImage : " + path + " "+ pos.getName());
    m_surface = loadImage(path);
    m_pos_size = new FTRect(pos.x, pos.y, m_surface.width, m_surface.height);
  }
  
  public FTImage(String path, FTRect pos, FTIQuaternion rot)
  {
    super("FTImage : " + path + " "+ pos.getName() + " " +rot.getName());
    m_surface = loadImage(path);
    m_pos_size = new FTRect(pos.x, pos.y, m_surface.width, m_surface.height);
    m_rot = rot;
  }
  
  public void setPixel(int x, int y, FTColor c)
  {
    m_surface.set(x,y,color(c.red(),c.green(),c.blue()));
  }
  
  public FTColor getPixel(int x, int y)
  {
    color c = m_surface.get(x,y);
    return new FTColor((int)red(c),(int)green(c),(int)blue(c));
  }
  
  public void setPosition(FTRect pos)
  {
    m_pos_size = new FTRect(pos.x, pos.y, m_pos_size.w, m_pos_size.h);
  }
  
  public void setSize(FTRect size)
  {
   m_surface.resize(size.w,size.h);
   m_pos_size = new FTRect(m_pos_size.x, m_pos_size.y, size.w, size.h);
  }
  
  public void setRotation(FTIQuaternion q)
  {
    m_rot = q;
  }
  
  public FTRect getPositionAndSize()
  {
    return m_pos_size;
  }
  
  public FTIQuaternion getRotation()
  {
    return m_rot;
  }
  
  public void draw_surface(int mode)
  {
    switch(mode)
    {
      case DRAW_ABS:
      _internal_draw(m_pos_size.x,m_pos_size.y);
      break;
      case DRAW_REL:
      _internal_draw(0,0);
      break;
    }
  }
  
  private void _internal_draw(int x, int y)
  {
    image(m_surface, x,y);
  }
}

class FTFont extends FTObject
{
  private PFont m_font;
  private FTColor m_color;
  private int m_size;
  private int align_1, align_2;
  
  public static final int DEFAULT_FORMAT_LOAD = 300;
  public static final int DYNAMIC_FORMAT_LOAD = 301;
  public static final int NONE_LOAD = 302;
  
  public FTFont(int mode_load, String path)
  {
    this(mode_load,path,0);
  }
  
  public FTFont(int mode_load, String path, int size)
  {
   super("FTFont : " + mode_load + " " + path + " " + size);
    m_color = new FTColor(FTColor.BLACK);
    m_size = size;
    align_1=CENTER;
    align_2=CENTER;
    switch(mode_load)
    {
      case DEFAULT_FORMAT_LOAD:
      m_font = loadFont(path);
      break;
      case DYNAMIC_FORMAT_LOAD:
      m_font = createFont(path,m_size);
      break;
      case NONE_LOAD:
      m_font = null;
      break;
    }
  }
  
  public void setSize(int s)
  {
    m_size = s;
  }
  
  public int getSize()
  {
    return m_size;
  }
  
  public void setAligns(int a, int b)
  {
    align_1=a;
    align_2=b;
  }
  
  public int[] getAligns()
  {
    int tab[] = new int[2];
    tab[0] = align_1;
    tab[1] = align_2;
    return tab;
  }
  
  public void setColor(FTColor c)
  {
    m_color = c;
  }
  
  public FTColor getColor()
  {
    return m_color;
  }
  
  public void pushFont()
  {
    if(m_font != null)
    {
    textFont(m_font);
    textSize(m_size);
    textAlign(align_1, align_2);
    fill(m_color.red(),m_color.green(),m_color.blue());
    }
  }
  
  public void popFont()
  {
    noFill();
  }
  
  public float getWidthOfText(String text)
  {
    return textWidth(text);
  }
}

class FTText extends FTObject
{
  private String m_text;
  private FTRect m_pos;
  private FTFont m_font;
  private FTIQuaternion m_rot;
  
  public static final int DRAW_ABS = 200;
  public static final int DRAW_REL = 201;
  
  public FTText(String text, FTRect pos)
  {
    this(text,pos,new FTIQuaternion(0,0,0),new FTFont(FTFont.NONE_LOAD,""));
  }
  
  public FTText(String text, FTRect pos, FTIQuaternion rot)
  {
    this(text,pos,rot,new FTFont(FTFont.NONE_LOAD,""));
  }
  
  public FTText(String text, FTRect pos, FTFont font)
  {
    this(text,pos,new FTIQuaternion(0,0,0),font);
  }
  
  public FTText(String text, FTRect pos, FTIQuaternion rot, FTFont font)
  {
   super("FTText : " + text + " " + pos.getName() + " " + rot.getName() + " " + font.getName());
    m_text = text;
    m_pos = pos;
    m_font = font;
    m_rot = rot;
  }
  
  public void setText(String s)
  {
    m_text = s;
  }
  
  public String getText()
  {
    return m_text;
  }
  
  public void setPosition(FTRect pos)
  {
    m_pos = pos;
  }
  
  public FTRect getPosition()
  {
    return m_pos;
  }
  
  public void setRotation(FTIQuaternion rot)
  {
    m_rot = rot;
  }
  
  public FTIQuaternion getRotation()
  {
    return m_rot;
  }
  
  public void setFont(FTFont f)
  {
    m_font = f;
  }
  
  public FTFont getFont()
  {
    return m_font;
  }
  
  public void draw_object(int mode)
  {
    switch(mode)
    {
      case DRAW_ABS:
      _internal_draw(m_pos.x,m_pos.y);
      break;
      case DRAW_REL:
      _internal_draw(0,0);
      break;
    }
  }
  
  private void _internal_draw(int x, int y)
  {
    m_font.pushFont();
     text(m_text,x,y);
    m_font.popFont();
  }
}

class FT3DObject extends FTObject
{
  private PShape m_shape;
  private FTRect m_pos;
  private FTRect m_size;
  private FTIQuaternion m_rot;
  
  public static final int DRAW_ABS = 200;
  public static final int DRAW_REL = 201;
  
  public FT3DObject(String path, FTRect pos, FTIQuaternion rot)
  {
    super("FT3DObject : " + path + " " + pos.getName() + " " + rot.getName());
    m_shape = loadShape(path);
    m_pos = pos;
    m_rot = rot;
    m_size = new FTRect(0,0,(int)m_shape.width,(int)m_shape.height);
  }
  
  private FT3DObject(PShape shape, FTRect pos, FTIQuaternion rot)
  {
    super("FT3DObject : " + pos.getName() + " " + rot.getName());
    m_shape=shape;
    m_pos = pos;
    m_rot = rot;
    m_size = new FTRect(0,0,(int)m_shape.width,(int)m_shape.height);
  }
  
  public void setPosition(FTRect pos)
  {
    m_pos = pos;
  }
  
  public void setSize(int coeff)
  {
    m_shape.scale(coeff);
    m_size =new FTRect(0,0,(int)m_shape.width,(int)m_shape.height);
  }
  
  public void setRotation(FTIQuaternion q)
  {
    m_rot = q;
  }
  
  public FTRect getPosition()
  {
    return m_pos;
  }
  
  public FTRect getSize()
  {
    return m_size;
  }
  
  public FTIQuaternion getRotation()
  {
    return m_rot;
  }
  
  public void addMove(FTMove move)
  {
    m_pos.x = m_pos.x + move.getMoveX();
    m_pos.y = m_pos.y + move.getMoveY();
    m_pos.z = m_pos.z + move.getMoveZ();
    
    m_rot.qx = m_rot.qx + move.getRotationX();
    m_rot.qy = m_rot.qy + move.getRotationY();
    m_rot.qz = m_rot.qz + move.getRotationZ();
  }
  
  public void draw_object(int mode)
  {
    switch(mode)
    {
      case DRAW_ABS:
      _internal_draw(m_pos.x,m_pos.y);
      break;
      case DRAW_REL:
      _internal_draw(0,0);
      break;
    }
  }
  
  public FT3DObject getCopyOfObject()
  {
    return getCopyOfObject(new FTRect(),new FTIQuaternion());
  }
  
  public FT3DObject getCopyOfObject(FTRect pos, FTIQuaternion rot)
  {
    return new FT3DObject(m_shape,pos,rot);
  }
  
  private void _internal_draw(int x, int y)
  {
    shape(m_shape,x,y);
  }
}

abstract class FTWidget extends FTObject
{
  public int m_id;
  public FTRect m_pos;
  public FTIQuaternion m_rot;
  
  public FTWidget(String name)
  {
    super(name);
  }
  
  public void setID(int id)
  {
    m_id = id;
  }
  
  public int getID()
  {
    return m_id;
  }
  
  public void setPosition(FTRect pos)
  {
    m_pos = pos;
  }
  
  public FTRect getPosition()
  {
    return m_pos;
  }
  
  abstract void onDraw(FTRender render);
  abstract void onActionPerform(FTEventMotion m);
  abstract void onFree();
}

class FTGui extends FTObject
{
  private ArrayList<FTWidget> m_list_widget;
  private ArrayList<Integer> m_list_id_widget;
  private FTRandom m_random;
  
  public FTGui()
  {
    super("FTGui : none");
    m_list_widget = new ArrayList<FTWidget>();
    m_list_id_widget = new ArrayList<Integer>();
    m_random = new FTRandom();
  }
  
  public void addWidget(FTWidget w)
  {
    w.setID(_getRandomId());
    m_list_widget.add(w);
  }
  
  public FTWidget getWidgetWithID(int id)
  {
    FTWidget w = null;
    int i;
    for(i=0;i<m_list_widget.size();i++)
    {
      if(m_list_widget.get(i).getID() == id)
      {
        w = m_list_widget.get(i);
      }
    }
    return w;
  }
  
  public void event_gui(FTEvent event)
  {
    if(event.getMethodRegister() != FTEvent.FUNCTION_REGISTER)
    {
      return;
    }
    
    FTEventMotion em = event.searchEvent();
    boolean is_repop = true;
    
    switch(em.getTypeEvent())
    {
      case FTEvent.NONE_EVENT:
      is_repop = false;
      break;
      case FTEvent.MOUSE_EVENT:
      case FTEvent.KEYBOARD_EVENT:
      _internal_dispatch_event(em);
      break;
    }
    
    if(is_repop)
    {
      event.add_event(em.getEvent());
    }
  }
  
  public void draw_gui(FTRender ren)
  {
    int i;
    for(i=0;i<m_list_widget.size();i++)
    {
      m_list_widget.get(i).onDraw(ren);
    }
  }
  
  private void _internal_dispatch_event(FTEventMotion e)
  {
    int i;
    for(i=0;i<m_list_widget.size();i++)
    {
      m_list_widget.get(i).onActionPerform(e);
    }
  }
  
  private int _getRandomId()
  {
    int nid = 0;
    boolean continuer = true;
    
    while(continuer)
    {
      nid = m_random.getRandomInt(0,100);
      if(!_isPresentInList(nid))
      {
        continuer=false;
      }
    }
    
    return nid;
  }
  
  private boolean _isPresentInList(int id)
  {
    int i;
    for(i=0;i<m_list_id_widget.size();i++)
    {
      if(m_list_id_widget.get(i) == id)
      {
        return true;
      }
    }
    
    return false;
  }
}

class FTLabel extends FTWidget
{
  private FTText m_text;
  
  public FTLabel(String text, FTRect pos)
  {
    this(text, pos, new FTIQuaternion(0,0,0));
  }
  
  public FTLabel(String text, FTRect pos, FTIQuaternion rot)
  {
    super("FTLabel : " + text + " " + pos.getName() + " " + rot.getName());
    m_text = new FTText(text,pos,rot,new FTFont(FTFont.DYNAMIC_FORMAT_LOAD,"Arial",14));
    m_pos=pos;
    m_rot=rot;
  }
  
  public void center_text_with_size()
  {
    FTFont f = m_text.getFont();
    float w = f.getWidthOfText(m_text.getText());
    
    //m_pos = new FTRect((int)(m_pos.x-(w/2)),(m_pos.y-f.getSize()/2), m_pos.w,m_pos.h);
 
    m_text.setPosition(new FTRect(0,0, 0,0));
  }
  
  @Override
  public void onDraw(FTRender render)
  {
    render.draw_text(m_text);
  }
  
  @Override
  public void onActionPerform(FTEventMotion e)
  {
  }
  
   @Override
  public void onFree()
  {
  }
}

class FTButton extends FTWidget
{
  private FTLabel m_text;
  private FTOnClickListener m_listener;
  private boolean is_listener = false;
  private FTColor m_color_stroke;
  
  public FTButton(String text, FTRect pos)
  {
    this(text,pos,new FTIQuaternion(0,0,0));
  }
  
  public FTButton(String text, FTRect pos, FTIQuaternion rot)
  {
    super("FTButton : " + text + " " + pos.getName() + " " + rot.getName());
    m_text = new FTLabel(text,new FTRect((pos.x+(pos.w/2)),(pos.y+(pos.h/2))),rot);
    m_text.center_text_with_size();
    m_pos=pos;
    m_rot=rot;
    m_color_stroke = new FTColor(0,0,0);
  }
  
  public void setOnClickListener(FTOnClickListener listener)
  {
    is_listener = true;
    m_listener = listener;
  }
  
  @Override
  public void onDraw(FTRender render)
  {
    stroke(2);
    stroke(m_color_stroke.red(),m_color_stroke.green(),m_color_stroke.blue());
    fill(165);
    render.r_translate((m_pos.x+(m_pos.w/2)),(m_pos.y+(m_pos.h/2)),m_pos.z);
    render.draw_box(m_pos);
    noFill();
    noStroke();
    m_text.onDraw(render);
    render.r_translate(-(m_pos.x+(m_pos.w/2)),-(m_pos.y+(m_pos.h/2)),-m_pos.z);
  }
  
  @Override
  public void onActionPerform(FTEventMotion e)
  {
    if(e.getTypeEvent() == FTEvent.MOUSE_EVENT)
    {
      FTMouseMotion m = e.getTypedEventMouse();
      
      if(m.getTypeMouseEvent() == FTEvent.MOUSE_RELEASED)
      {
        int mx = m.getMouseX();
        int my = m.getMouseY();
        if(((mx >= m_pos.x) && mx <= (m_pos.x+m_pos.w)) && ((my >= m_pos.y) && my <= (m_pos.y+m_pos.h)))
        {
          if(is_listener)
          {
            m_listener.onClick(m_id);
          }
        }
      }
      else if(m.getTypeMouseEvent() == FTEvent.MOUSE_MOVED)
      {
        int mx = m.getMouseX();
        int my = m.getMouseY();
        if(((mx >= m_pos.x) && mx <= (m_pos.x+m_pos.w)) && ((my >= m_pos.y) && my <= (m_pos.y+m_pos.h)))
        {
          m_color_stroke = new FTColor(255,0,0);
        }
        else
        {
          m_color_stroke = new FTColor(0,0,0);
        }
      }
    }
  }
  
   @Override
  public void onFree()
  {
  }
}

class FTAudioSample extends FTObject
{
  private Long currentFrame=0L; 
  private Clip clip=null; 
  private String status=""; 
  private AudioInputStream audioInputStream = null;
  private String path = "";
  private int number_of_turn = 0;
  
  public static final int LOOP_INFINITY = Clip.LOOP_CONTINUOUSLY;
  
  public FTAudioSample(String p)
  {
    this(p,LOOP_INFINITY);
  }
  
  public FTAudioSample(String p, int not)
  {
    super("FTAudioSample : " + p + " " + not);
    status = "none";
    path = p;
    number_of_turn = not;
    
     try{
audioInputStream =  
                AudioSystem.getAudioInputStream(new File(path).getAbsoluteFile());
    }
    catch(UnsupportedAudioFileException e)
    {
      e.printStackTrace(); 
    }
    catch(IOException e)
    {
      e.printStackTrace(); 
    }
    
    try
    {        
        // create clip reference 
        clip = AudioSystem.getClip(); 
          
        // open audioInputStream to the clip 
        clip.open(audioInputStream); 
    }
    catch(LineUnavailableException e)
    {
      e.printStackTrace(); 
    }
    catch(IOException e)
    {
      e.printStackTrace(); 
    }
          
        clip.loop(number_of_turn);
  }
  
  public void play()
  {
    clip.start();
    status="play";
  }
  
  public void pause()
  {
    if (status.equals("paused"))  
        { 
            return; 
        } 
        currentFrame = clip.getMicrosecondPosition(); 
        clip.stop(); 
        status = "paused"; 
  }
  
  public void resume()
  {
    if (status.equals("play"))  
        { 
            return; 
        } 
        clip.close();
        try
        {
          _resetAudioStream(); 
        }
        catch(UnsupportedAudioFileException e)
        {
          e.printStackTrace(); 
        }
        catch(IOException e)
        {
          e.printStackTrace(); 
        }
        catch(LineUnavailableException e)
        {
          e.printStackTrace(); 
        }
        clip.setMicrosecondPosition(currentFrame); 
        play();
        status="play";
  }
  
  public void stop()
  {
        status="stop";
        currentFrame = 0L; 
        clip.stop(); 
        clip.close(); 
  }
  
  public void restart()
  {
        clip.stop(); 
        clip.close(); 
        try
            {
              _resetAudioStream(); 
            }
            catch(UnsupportedAudioFileException e)
            {
              e.printStackTrace(); 
            }
            catch(IOException e)
            {
              e.printStackTrace(); 
            }
            catch(LineUnavailableException e)
            {
              e.printStackTrace(); 
            }
        currentFrame = 0L; 
        clip.setMicrosecondPosition(0); 
        play();
  }
  
  public void jump(long c)
  {
    if (c > 0 && c < clip.getMicrosecondLength())  
        { 
            clip.stop(); 
            clip.close(); 
            try
            {
              _resetAudioStream(); 
            }
            catch(UnsupportedAudioFileException e)
            {
              e.printStackTrace(); 
            }
            catch(IOException e)
            {
              e.printStackTrace(); 
            }
            catch(LineUnavailableException e)
            {
              e.printStackTrace(); 
            }
            currentFrame = c; 
            clip.setMicrosecondPosition(c); 
            play(); 
        } 
  }
  
  public long getCurrentFrame()
  {
    return currentFrame;
  }
  
  public String getCurrentStatus()
  {
    return status;
  }
  
  private void _resetAudioStream() throws UnsupportedAudioFileException, IOException, 
                                            LineUnavailableException  
    { 
        audioInputStream = AudioSystem.getAudioInputStream( 
        new File(path).getAbsoluteFile()); 
        clip.open(audioInputStream); 
        clip.loop(number_of_turn); 
    }
}

abstract class FTFile extends FTObject{
  private BufferedReader reader;
  private PrintWriter output;
  private ArrayList<String> buffer = new ArrayList<String>();
  private String mode_f;
  
  protected FTFile(String path, String mode)
  {
    super("FTFile : " + path +" " + mode);
    mode_f=mode;
    if(mode == "r")
    {
      reader = createReader(path);
      fillbuffer();
      try{
      reader.close();
      } catch (IOException e) {
      e.printStackTrace();
      }
    }
    else if(mode == "w")
    {
      output = createWriter(path);
    }
    else if(mode == "wr")
    {
      reader = createReader(path);
      fillbuffer();
      try{
      reader.close();
      } catch (IOException e) {
      e.printStackTrace();
      }
    }
    else if(mode == "a")
    {
      fillbuffer();
      try{
      reader.close();
      } catch (IOException e) {
      e.printStackTrace();
      }
    }
  }
  
  private void fillbuffer()
  {
      try {
        String line;
      while ((line = reader.readLine()) != null) {
        buffer.add(line);
        }
      } catch (IOException e) {
      e.printStackTrace();
      }
  }
  
  protected void fwrite(String w)
  {
    if(mode_f == "w" || mode_f == "wr" || mode_f == "a")
    {
    output.println(w);
    }
  }
  
  protected String fread(int line)
  {
    if(mode_f == "wr" || mode_f == "r")
    {
    return buffer.get(line);
    }
    
    return "null";
  }
  
  protected int get_size_lines()
  {
    return buffer.size();
  }
  
  protected void fclose()
  {
    if(mode_f == "w")
    {
      output.flush();
      output.close();
    }
    else if(mode_f == "wr")
    {
      output.flush();
      output.close();
    }
    else if(mode_f == "a")
    {
      output.flush();
      output.close();
    }
  }
}

class FTFileText extends FTFile{
  private int current_line=0;
  
  public FTFileText(String name, String mode)
  {
    super(name,mode);
  }
  
  public void write_text(String text)
  {
    super.fwrite(text);
  }
  
  public String read_line()
  {
    return super.fread(current_line);
  }
  
  public ArrayList<String> read_lines()
  {
    ArrayList<String> tmp = new ArrayList<String>();
    int max=super.get_size_lines();
    int i;
    for(i=0;i<max;i++)
    {
      tmp.add(super.fread(current_line));
    }
    
    return tmp;
  }
  
  public void set_read_line(int a)
  {
    current_line=a;
  }
  
  public void set_start_file()
  {
    current_line=0;
  }
  
  public void fclose()
  {
    super.fclose();
  }
}

interface FTCallable
{
  public void onCall();
}

class FTThread extends Thread
{
  private Thread t;
  private String threadName;
  private FTCallable callable;
  
  public FTThread(String name)
  {
    threadName = name;
    t = new Thread (this, threadName);
    callable = null;
  }
  
  public String getThreadName()
  {
    return threadName;
  }
  
  public void setCallable(FTCallable c)
  {
    callable = c;
  }
  
  public void start()
  {
    if(t != null && callable != null)
    {
      t.start();
    }
  }
  
  public void run()
  {
    callable.onCall();
  }
}

class FTHttpClient extends FTObject{
 
 private final String USER_AGENT = "Mozilla/5.0";
 private String urlString = "";
 
 public FTHttpClient(String url)
 {
   super("FTHttpClient : " + url);
   urlString = url;
 }

 public String sendingGetRequest() throws Exception {
  URL url = new URL(urlString);
  HttpURLConnection con = (HttpURLConnection) url.openConnection();
 
  // By default it is GET request
  con.setRequestMethod("GET");
 
  //add request header
  con.setRequestProperty("User-Agent", USER_AGENT);
 
  int responseCode = con.getResponseCode();
  System.out.println("Sending get request : "+ url);
  System.out.println("Response code : "+ responseCode);
 
  // Reading response from input Stream
  BufferedReader in = new BufferedReader(
          new InputStreamReader(con.getInputStream()));
  String output;
  StringBuffer response = new StringBuffer();
 
  while ((output = in.readLine()) != null) {
   response.append(output);
  }
  in.close();
 
 return response.toString();
 }
 
 public String sendingPostRequest(String postJsonData) throws Exception {
  URL obj = new URL(urlString);
  HttpURLConnection con = (HttpURLConnection) obj.openConnection();
 
        // Setting basic post request
  con.setRequestMethod("POST");
  con.setRequestProperty("User-Agent", USER_AGENT);
  //con.setRequestProperty("Accept-Language", "en-US,en;q=0.5");
  con.setRequestProperty("Content-Type","application/json");
  
  // Send post request
  con.setDoOutput(true);
  DataOutputStream wr = new DataOutputStream(con.getOutputStream());
  wr.writeBytes(postJsonData);
  wr.flush();
  wr.close();
 
  int responseCode = con.getResponseCode();
  System.out.println("nSending 'POST' request to URL : " + urlString);
  System.out.println("Post Data : " + postJsonData);
  System.out.println("Response Code : " + responseCode);
 
  BufferedReader in = new BufferedReader(
          new InputStreamReader(con.getInputStream()));
  String output;
  StringBuffer response = new StringBuffer();
 
  while ((output = in.readLine()) != null) {
   response.append(output);
  }
  in.close();
  
  return response.toString();
 }
}

class FTRect extends FTObject
{
  public int x, y, z;
  public int w, h, p;
  
  public FTRect()
  {
    this(0,0,0,0,0,0);
  }
  
  public FTRect(int a, int b)
  {
    this(a,b,0,0,0,0);
  }
  
  public FTRect(int a, int b, int c)
  {
    this(a,b,c,0,0,0);
  }
  
  public FTRect(int a, int b, int c, int d)
  {
    this(a,b,0,c,d,0);
  }
  
  public FTRect(int a, int b, int c, int d, int e, int f)
  {
    super("FTRect : " + a+ " " + b + " " + c + " " + d + " " + e + " " + f);
    x=a;
    y=b;
    z=c;
    w=d;
    h=e;
    p=f;
  }
  
  public boolean isInRect(FTRect r)
  {
    if(r.x > x && r.y > y && r.x < (x+w) && r.y < (y+h))
    {
      return true;
    }
    return false;
   }
}

class FTColor extends FTObject
{
    private int a;
    private int r;
    private int g;
    private int b;

    public final static int RED = 1;
    public final static int GREEN = 2;
    public final static int BLUE = 3;
    public final static int BLACK = 4;
    public final static int WHITE = 5;

    public FTColor(int id)
    {
      super("FTColor : " + id);
        switch(id)
        {
            case RED:
                a=0;
                r=255;
                g=0;
                b=0;
                break;
            case GREEN:
                a=0;
                r=0;
                g=255;
                b=0;
                break;
            case BLUE:
                a=0;
                r=0;
                g=0;
                b=255;
                break;
            case WHITE:
                a=0;
                r=255;
                b=255;
                g=255;
                break;
            case BLACK:
                a=0;
                r=0;
                b=0;
                g=0;
                break;
        }
    }
    
    public FTColor(int a1, int b2, int c3)
    {
      this(0,a1,b2,c3);
    }

    public FTColor(int a1, int b2, int c3, int db)
    {
      super("FTColor : " + a1 + " " + b2 + " " + c3 + " " +db);
        a=a1;
        r=b2;
        g=c3;
        b=db;
    }

    public int alpha()
    {
        return a;
    }

    public int red()
    {
        return r;
    }

    public int green()
    {
        return g;
    }

    public int blue()
    {
        return b;
    }
}

class FTMove extends FTObject
{
    private int m_move_x;
    private int m_move_y;
    private int m_move_z;
    private FTIQuaternion m_move_rot;

    public FTMove(int move_x, int move_y)
    {
      this(move_x,move_y,0,new FTIQuaternion(0,0,0));
    }
    
    public FTMove(FTIQuaternion rot)
    {
        this(0,0,0,rot);
    }
    
    public FTMove(int move_x, int move_y, FTIQuaternion rot)
    {
        this(move_x,move_y,0,rot);
    }
    
    public FTMove(int move_x, int move_y, int move_z)
    {
        this(move_x,move_y,move_z,new FTIQuaternion(0,0,0));
    }
    
    public FTMove(int move_x, int move_y, int move_z, FTIQuaternion rot)
    {
      super("FTMove : " + move_x + " "+ move_y + " "+ move_z + " " + rot.getName());
        m_move_x = move_x;
        m_move_y = move_y;
        m_move_z = move_z;
        m_move_rot = rot;
    }
    
    public FTRect applyMove(FTRect r)
    {
      return new FTRect(r.x+m_move_x,r.y+m_move_y,r.z+m_move_z);
    }
    
    public FTIQuaternion applyRotation(FTIQuaternion r)
    {
      return new FTIQuaternion(r.qx+m_move_rot.qx,r.qy+m_move_rot.qy,r.qz+m_move_rot.qz);
    }

    public int getMoveX()
    {
        return m_move_x;
    }

    public int getMoveY()
    {
        return m_move_y;
    }
    
    public int getMoveZ()
    {
        return m_move_z;
    }
    
    public float getRotationX()
    {
        return m_move_rot.qx;
    }
    
    public float getRotationY()
    {
        return m_move_rot.qy;
    }
    
    public float getRotationZ()
    {
        return m_move_rot.qz;
    }
}
class FTIQuaternion extends FTObject
{
  public float qx,qy,qz;
  
  public final static int SYSTEM_DEGREE = 100;
  public final static int SYSTEM_RADIAN = 101;
  
  public FTIQuaternion()
  {
    super("FTQuaternion : none");
   qx=0.0;
   qy=0.0;
   qz=0.0;
  }
  
  public FTIQuaternion(float a, float b, float c)
  {
    this(SYSTEM_RADIAN,a,b,c);
  }
   
  public FTIQuaternion(int system_angle, float a, float b, float c)
  {
     super("FTQuaternion :" + system_angle + " "+ a + " " + b + " " + c);
     switch(system_angle)
     {
       case SYSTEM_DEGREE:
         qx=radians(a);
         qy=radians(b);
         qz=radians(c);
       break;
       default:
         qx=a;
         qy=b;
         qz=c;
       break;
     }
  }
  
  public FTIQuaternion getSwapSystem()
  {
    FTIQuaternion n = new FTIQuaternion();
    n.qx=degrees(qx);
    n.qy=degrees(qy);
    n.qz=degrees(qz);
    return n;
  }
}

class FTRandom extends FTObject
{
  private Random r;
  public FTRandom()
  {
    super("FTRandom : none");
    r = new Random();
  }
  
  public int getRandomInt(int min, int max)
  {
    return r.nextInt((max - min) + 1) + min;
  }
}
