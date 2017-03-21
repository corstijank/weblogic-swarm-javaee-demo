/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */
package net.staticsmustdie.javaee;

import java.util.logging.Logger;

import javax.ejb.PostActivate;
import javax.ejb.Singleton;
import javax.ejb.Startup;
import javax.ejb.Stateless;

/**
 *
 * @author Corstijan.Korstmit
 */
@Singleton
@Startup
public class StartUpBean {
    
    private static Logger logger = Logger.getLogger(StartUpBean.class.getName());

    @PostActivate
    public void onStartUp() {
        logger.warning("Bean started");
        logger.warning("Bean started");
        logger.warning("Bean started");
        logger.warning("Bean started");
        logger.warning("Bean started");
        logger.warning("Bean started");
        logger.warning("Bean started");
    }
}
